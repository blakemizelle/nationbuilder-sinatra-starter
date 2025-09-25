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

# Global token store - simple and works
$token_store = case ENV['TOKEN_STORE']
when 'redis'
  RedisStore.new(ENV['REDIS_URL'])
else
  MemoryStore.new
end

def token_store
  $token_store
end

# Make token_store available to views
helpers do
  def token_store
    $token_store
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
    session_id: session.id.to_s
  )
end

# Routes

# Home page
get '/' do
  erb :index
end

# Initiate OAuth login
get '/login' do
  begin
    # Validate required environment variables
    required_vars = %w[NB_CLIENT_ID NB_BASE_URL NB_REDIRECT_URI NB_SCOPES]
    missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }
    
    if missing_vars.any?
      halt 500, "Missing required environment variables: #{missing_vars.join(', ')}"
    end

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
  rescue => e
    puts "OAuth login error: #{e.message}"
    puts "Backtrace: #{e.backtrace.first(3)}"
    halt 500, "Login failed: #{e.message}"
  end
end

# OAuth callback
get '/oauth/callback' do
  begin
    # Verify state parameter
    if params[:state] != session[:oauth_state]
      puts "Invalid state parameter. Expected: #{session[:oauth_state]}, Got: #{params[:state]}"
      halt 400, "Invalid state parameter - possible CSRF attack"
    end

    # Check for OAuth errors from NationBuilder
    if params[:error]
      error_desc = params[:error_description] || 'No description provided'
      puts "OAuth error from NationBuilder: #{params[:error]} - #{error_desc}"
      halt 400, "OAuth error: #{params[:error]} - #{error_desc}"
    end

    # Validate required parameters
    if params[:code].nil? || params[:code].empty?
      halt 400, "Missing authorization code"
    end

    if session[:code_verifier].nil?
      halt 400, "Missing code verifier - session may have expired"
    end

    # Exchange code for tokens
    tokens = oauth_client.exchange_code_for_tokens(
      code: params[:code],
      code_verifier: session[:code_verifier]
    )

    # Validate token response
    if tokens.nil? || tokens['access_token'].nil?
      halt 500, "Invalid token response from NationBuilder"
    end

    # Store tokens
    token_store.store_tokens(session.id.to_s, tokens)

    # Clear session data
    session.delete(:oauth_state)
    session.delete(:code_verifier)

    redirect '/status'
  rescue => e
    puts "OAuth callback error: #{e.message}"
    puts "Backtrace: #{e.backtrace.first(3)}"
    halt 500, "Authentication failed: #{e.message}"
  end
end

# Status page - shows API data
get '/status' do
  begin
    tokens = token_store.get_tokens(session.id.to_s)
    
    if tokens.nil?
      puts "No tokens found for session #{session.id}"
      redirect '/'
    end

    # Get signup info from NationBuilder
    signup_info = nb_api.get_signup_info

    # Extract user display name from signup info
    user_display_name = signup_info['username'] || signup_info['full_name'] || 'Connected User'

    erb :status, locals: {
      tokens: tokens,
      user_display_name: user_display_name,
      nation_slug: ENV['NB_BASE_URL'].gsub('https://', '').gsub('.nationbuilder.com', '')
    }
  rescue => e
    puts "Status page error: #{e.message}"
    puts "Backtrace: #{e.backtrace.first(3)}"
    
    # If API call fails, clear tokens and redirect to login
    token_store.clear_tokens(session.id.to_s)
    redirect '/'
  end
end

# Logout
get '/logout' do
  token_store.clear_tokens(session.id.to_s)
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
  error_message = env['sinatra.error']&.message || 'An error occurred'
  
  # Log error details for debugging
  puts "ERROR #{response.status}: #{error_message}"
  puts "Request path: #{request.path}"
  puts "Request method: #{request.request_method}"
  
  { 
    error: true, 
    message: error_message,
    status: response.status,
    timestamp: Time.now.iso8601
  }.to_json
end

# Global error handler for unhandled exceptions
error do
  error_message = env['sinatra.error']&.message || 'Internal server error'
  
  # Log full error details
  puts "UNHANDLED ERROR: #{error_message}"
  puts "Backtrace: #{env['sinatra.error']&.backtrace&.first(5)}"
  puts "Request: #{request.request_method} #{request.path}"
  
  content_type :json
  { 
    error: true, 
    message: 'An unexpected error occurred',
    status: 500,
    timestamp: Time.now.iso8601
  }.to_json
end