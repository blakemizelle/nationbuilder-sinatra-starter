require_relative 'token_store'
require 'redis'
require 'json'

# Redis-based token storage implementation
class RedisStore < TokenStore
  def initialize(redis_url = nil)
    @redis_url = redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    @redis = Redis.new(url: @redis_url)
  end

  def store_tokens(session_id, tokens)
    key = token_key(session_id)
    @redis.setex(key, 86400, tokens.to_json) # 24 hour TTL
  end

  def get_tokens(session_id)
    key = token_key(session_id)
    data = @redis.get(key)
    return nil unless data
    
    JSON.parse(data)
  rescue JSON::ParserError
    nil
  end

  def clear_tokens(session_id)
    key = token_key(session_id)
    @redis.del(key)
  end

  private

  def token_key(session_id)
    "nb_tokens:#{session_id}"
  end
end