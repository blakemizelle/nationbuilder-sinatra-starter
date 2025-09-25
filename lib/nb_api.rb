require 'httparty'
require 'json'

# NationBuilder v2 API client
class NbApi
  include HTTParty

  def initialize(base_url:, token_store:, session_id:)
    @base_url = base_url
    @token_store = token_store
    @session_id = session_id
  end

  # Make an authenticated API request
  def authenticated_request(method:, path:, params: {})
    tokens = @token_store.get_tokens(@session_id)
    
    if tokens.nil?
      raise "No tokens found for session"
    end

    # Check if token needs refresh
    if @token_store.token_expires_soon?(tokens)
      tokens = refresh_tokens_if_needed(tokens)
    end

    headers = {
      'Authorization' => "Bearer #{tokens['access_token']}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }

    url = "#{@base_url}#{path}"
    
    case method.to_s.upcase
    when 'GET'
      response = self.class.get(url, headers: headers, query: params)
    when 'POST'
      response = self.class.post(url, headers: headers, body: params.to_json)
    when 'PUT'
      response = self.class.put(url, headers: headers, body: params.to_json)
    when 'DELETE'
      response = self.class.delete(url, headers: headers)
    else
      raise "Unsupported HTTP method: #{method}"
    end

    if response.code == 401
      # Token might be invalid, try to refresh
      tokens = refresh_tokens_if_needed(tokens)
      headers['Authorization'] = "Bearer #{tokens['access_token']}"
      
      # Retry the request
      case method.to_s.upcase
      when 'GET'
        response = self.class.get(url, headers: headers, query: params)
      when 'POST'
        response = self.class.post(url, headers: headers, body: params.to_json)
      when 'PUT'
        response = self.class.put(url, headers: headers, body: params.to_json)
      when 'DELETE'
        response = self.class.delete(url, headers: headers)
      end
    end

    if response.success?
      JSON.parse(response.body) rescue response.body
    else
      raise "API request failed: #{response.code} - #{response.body}"
    end
  end

  # Get signup information (NationBuilder term for authenticated user)
  def get_signup_info
    authenticated_request(method: 'GET', path: '/api/v2/signups/me')
  end

  private

  def refresh_tokens_if_needed(tokens)
    return tokens unless @token_store.token_expires_soon?(tokens)

    begin
      oauth_client = OAuthClient.new(
        client_id: ENV['NB_CLIENT_ID'],
        client_secret: ENV['NB_CLIENT_SECRET'],
        redirect_uri: ENV['NB_REDIRECT_URI'],
        base_url: ENV['NB_BASE_URL'],
        scopes: ENV['NB_SCOPES']
      )

      new_tokens = oauth_client.refresh_tokens(refresh_token: tokens['refresh_token'])
      @token_store.store_tokens(@session_id, new_tokens)
      new_tokens
    rescue => e
      # If refresh fails, clear tokens and let user re-authenticate
      @token_store.clear_tokens(@session_id)
      raise "Token refresh failed: #{e.message}"
    end
  end
end