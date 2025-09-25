require 'sinatra'
require 'dotenv'
require 'securerandom'
require 'json'
require_relative 'lib/oauth_client'
require_relative 'lib/nb_api'
require_relative 'lib/token_store/memory_store'
require_relative 'lib/token_store/redis_store'

# Load environment variables
Dotenv.load

# Configure Sinatra
set :session_secret, ENV['SESSION_SECRET']
set :sessions, true
set :session_store, Rack::Session::Pool
set :views, 'views'
set :public_folder, 'public'

# Configure session security
configure :production do
  set :session_cookie_options, {
    secure: true,
    httponly: true,
    same_site: :lax
  }
end

configure :development do
  set :session_cookie_options, {
    httponly: true,
    same_site: :lax
  }
end

# Initialize token store
def token_store
  @token_store ||= case ENV['TOKEN_STORE']
  when 'redis'
    RedisStore.new(ENV['REDIS_URL'])
  else
    MemoryStore.new
  end
end

# Initialize OAuth client
def oauth_client
  @oauth_client ||= OAuthClient.new(
    client_id: ENV['NB_CLIENT_ID'],
    client_secret: ENV['NB_CLIENT_SECRET'],
    redirect_uri: ENV['NB_REDIRECT_URI'],
    base_url: ENV['NB_BASE_URL'],
    scopes: ENV['NB_SCOPES']
  )
end

# Initialize NationBuilder API client
def nb_api
  @nb_api ||= NbApi.new(
    base_url: ENV['NB_BASE_URL'],
    token_store: token_store,
    session_id: session.id
  )
end

# Routes

# Home page
get '/' do
  erb :index
end

# Initiate OAuth login
get '/login' do
  # Generate state for CSRF protection
  state = SecureRandom.hex(32)
  session[:oauth_state] = state

  # Generate PKCE pair
  pkce = oauth_client.generate_pkce_pair
  session[:code_verifier] = pkce[:code_verifier]

  # Build authorization URL
  auth_url = oauth_client.authorization_url(
    state: state,
    code_challenge: pkce[:code_challenge]
  )

  redirect auth_url
end

# OAuth callback
get '/oauth/callback' do
  # Verify state parameter
  if params[:state] != session[:oauth_state]
    halt 400, "Invalid state parameter"
  end

  # Check for error
  if params[:error]
    halt 400, "OAuth error: #{params[:error]} - #{params[:error_description]}"
  end

  # Exchange code for tokens
  begin
    tokens = oauth_client.exchange_code_for_tokens(
      code: params[:code],
      code_verifier: session[:code_verifier]
    )

    # Store tokens
    token_store.store_tokens(session.id, tokens)

    # Clear session data
    session.delete(:oauth_state)
    session.delete(:code_verifier)

    redirect '/status'
  rescue => e
    halt 500, "Token exchange failed: #{e.message}"
  end
end

# Status page - shows API data
get '/status' do
  tokens = token_store.get_tokens(session.id)
  
  if tokens.nil?
    redirect '/'
  end

  begin
    # Get account info from NationBuilder
    account_info = nb_api.get_account_info
    site_info = nb_api.get_site_info

    erb :status, locals: {
      account_info: account_info,
      site_info: site_info,
      tokens: tokens,
      user_name: account_info['first_name'] && account_info['last_name'] ? "#{account_info['first_name']} #{account_info['last_name']}" : account_info['email'],
      nation_slug: ENV['NB_BASE_URL'].gsub('https://', '').gsub('.nationbuilder.com', '')
    }
  rescue => e
    # If API call fails, clear tokens and redirect to login
    token_store.clear_tokens(session.id)
    redirect '/'
  end
end

# Logout
get '/logout' do
  token_store.clear_tokens(session.id)
  session.clear
  redirect '/'
end

# Health check
get '/health' do
  content_type :json
  { ok: true, timestamp: Time.now.iso8601 }.to_json
end

# Error handlers
error 400..599 do
  content_type :json
  { error: true, message: env['sinatra.error']&.message || 'An error occurred' }.to_json
end