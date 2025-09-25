# Abstract base class for token storage
class TokenStore
  def store_tokens(session_id, tokens)
    raise NotImplementedError, "Subclasses must implement store_tokens"
  end

  def get_tokens(session_id)
    raise NotImplementedError, "Subclasses must implement get_tokens"
  end

  def clear_tokens(session_id)
    raise NotImplementedError, "Subclasses must implement clear_tokens"
  end

  def store_user_data(session_id, user_data)
    raise NotImplementedError, "Subclasses must implement store_user_data"
  end

  def get_user_data(session_id)
    raise NotImplementedError, "Subclasses must implement get_user_data"
  end

  def token_expired?(tokens)
    return true unless tokens && tokens['expires_at']
    
    Time.now.to_i >= tokens['expires_at']
  end

  def token_expires_soon?(tokens, buffer_seconds = 30)
    return true unless tokens && tokens['expires_at']
    
    Time.now.to_i >= (tokens['expires_at'] - buffer_seconds)
  end
end