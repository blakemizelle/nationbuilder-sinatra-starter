require_relative 'token_store'

# In-memory token storage implementation
class MemoryStore < TokenStore
  def initialize
    @tokens = {}
  end

  def store_tokens(session_id, tokens)
    @tokens[session_id] = tokens.dup
  end

  def get_tokens(session_id)
    @tokens[session_id]
  end

  def clear_tokens(session_id)
    @tokens.delete(session_id)
  end
end