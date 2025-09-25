require 'securerandom'
require 'digest'
require 'httparty'
require 'json'

class OAuthClient
  include HTTParty

  def initialize(client_id:, client_secret: nil, redirect_uri:, base_url:, scopes:)
    @client_id = client_id
    @client_secret = client_secret
    @redirect_uri = redirect_uri
    @base_url = base_url
    @scopes = scopes
  end

  # Generate PKCE code verifier and challenge
  def generate_pkce_pair
    code_verifier = generate_code_verifier
    code_challenge = generate_code_challenge(code_verifier)
    
    {
      code_verifier: code_verifier,
      code_challenge: code_challenge
    }
  end

  # Generate authorization URL with PKCE
  def authorization_url(state:, code_challenge:)
    params = {
      response_type: 'code',
      client_id: @client_id,
      redirect_uri: @redirect_uri,
      scope: @scopes,
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }

    query_string = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    "#{@base_url}/oauth/authorize?#{query_string}"
  end

  # Exchange authorization code for tokens
  def exchange_code_for_tokens(code:, code_verifier:)
    body = {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: @redirect_uri,
      client_id: @client_id,
      code_verifier: code_verifier
    }

    # Add client secret if available (for confidential clients)
    body[:client_secret] = @client_secret if @client_secret

    response = self.class.post(
      "#{@base_url}/oauth/token",
      body: body,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    if response.success?
      tokens = JSON.parse(response.body)
      # Add expiration timestamp
      tokens['expires_at'] = Time.now.to_i + tokens['expires_in'].to_i
      tokens
    else
      raise "Token exchange failed: #{response.code} - #{response.body}"
    end
  end

  # Refresh access token
  def refresh_tokens(refresh_token:)
    body = {
      grant_type: 'refresh_token',
      refresh_token: refresh_token,
      client_id: @client_id
    }

    # Add client secret if available
    body[:client_secret] = @client_secret if @client_secret

    response = self.class.post(
      "#{@base_url}/oauth/token",
      body: body,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    if response.success?
      tokens = JSON.parse(response.body)
      tokens['expires_at'] = Time.now.to_i + tokens['expires_in'].to_i
      tokens
    else
      raise "Token refresh failed: #{response.code} - #{response.body}"
    end
  end

  private

  def generate_code_verifier
    # Generate a cryptographically random string using the characters
    # [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
    # with a minimum length of 43 characters and a maximum length of 128 characters
    SecureRandom.urlsafe_base64(32)
  end

  def generate_code_challenge(code_verifier)
    # SHA256 hash of the code verifier, base64url encoded
    digest = Digest::SHA256.digest(code_verifier)
    Base64.urlsafe_encode64(digest, padding: false)
  end
end