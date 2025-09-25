# NationBuilder Sinatra Starter

A reference implementation of NationBuilder OAuth 2.0 authentication using the Authorization Code flow with PKCE (Proof Key for Code Exchange). This application demonstrates secure token handling, automatic refresh, and integration with NationBuilder's v2 API.

## Architecture

### OAuth 2.0 Implementation

The application implements RFC 7636 PKCE for public clients:

- **Code Verifier**: Cryptographically random string (43-128 characters)
- **Code Challenge**: SHA256 hash of verifier, base64url encoded
- **State Parameter**: CSRF protection using SecureRandom.hex(32)
- **Token Storage**: Session-based with automatic refresh

### Token Management

- **Storage**: In-memory hash with Redis interface for production scaling
- **Refresh**: Automatic refresh when tokens expire within 30 seconds
- **Security**: Tokens never logged or exposed to client-side JavaScript
- **Session Handling**: Uses `session.id.to_s` for consistent key generation

### API Integration

- **Endpoint**: `/api/v2/signups/me` - Returns authenticated user's signup data
- **Authentication**: Bearer token in Authorization header
- **Error Handling**: 401 responses trigger token refresh, failed refresh clears session

## Implementation Details

### Core Components

**OAuthClient** (`lib/oauth_client.rb`)
- Generates PKCE code verifier/challenge pairs
- Builds authorization URLs with proper parameters
- Exchanges authorization codes for access/refresh tokens
- Handles token refresh requests

**NbApi** (`lib/nb_api.rb`)
- Makes authenticated requests to NationBuilder API
- Implements automatic token refresh on 401 responses
- Handles token expiration detection and refresh

**TokenStore** (`lib/token_store/`)
- Abstract interface for token storage
- MemoryStore: In-memory hash for development
- RedisStore: Redis-based storage for production scaling

### Session Security

```ruby
configure :production do
  set :session_cookie_options, {
    secure: true,
    httponly: true,
    same_site: :lax
  }
end
```

### Environment Configuration

Required variables:
- `SESSION_SECRET`: Cryptographically secure session encryption key
- `NB_CLIENT_ID`: NationBuilder OAuth application client ID
- `NB_CLIENT_SECRET`: OAuth client secret (optional for PKCE-only)
- `NB_REDIRECT_URI`: OAuth callback URL
- `NB_BASE_URL`: NationBuilder instance URL (e.g., `https://your-nation.nationbuilder.com`)
- `NB_SCOPES`: OAuth scopes (typically `default`)
- `TOKEN_STORE`: Storage backend (`memory` or `redis`)

## Setup

### Prerequisites

- Ruby 3.4+
- Bundler
- NationBuilder account with OAuth application

### Installation

```bash
git clone https://github.com/blakemizelle/nationbuilder-sinatra-starter.git
cd nationbuilder-sinatra-starter
bundle install
cp .env.example .env
```

### Configuration

1. **NationBuilder OAuth App Setup**
   - Navigate to Settings → API in NationBuilder admin
   - Create OAuth application
   - Set redirect URI: `http://localhost:4567/oauth/callback`
   - Copy Client ID and Secret to `.env`

2. **Environment Variables**
   ```env
   SESSION_SECRET=your-cryptographically-secure-key
   NB_CLIENT_ID=your-client-id
   NB_CLIENT_SECRET=your-client-secret
   NB_REDIRECT_URI=http://localhost:4567/oauth/callback
   NB_BASE_URL=https://your-nation.nationbuilder.com
   NB_SCOPES=default
   TOKEN_STORE=memory
   ```

3. **Run Application**
   ```bash
   ruby app.rb
   ```

## API Endpoints

| Route | Method | Purpose |
|-------|--------|---------|
| `/` | GET | Home page with connection status |
| `/login` | GET | Initiates OAuth flow with PKCE |
| `/oauth/callback` | GET | Handles OAuth callback and token exchange |
| `/status` | GET | Displays connection status and user info |
| `/logout` | GET | Clears session and stored tokens |
| `/health` | GET | Health check endpoint |

## Production Deployment

### Heroku Deployment

```bash
heroku create your-app-name
heroku config:set SESSION_SECRET=your-production-secret
heroku config:set NB_CLIENT_ID=your-client-id
heroku config:set NB_CLIENT_SECRET=your-client-secret
heroku config:set NB_REDIRECT_URI=https://your-app-name.herokuapp.com/oauth/callback
heroku config:set NB_BASE_URL=https://your-nation.nationbuilder.com
heroku config:set NB_SCOPES=default
heroku config:set TOKEN_STORE=memory
git push heroku main
```

### Redis Token Storage

For production scaling with multiple NationBuilder instances:

```bash
heroku addons:create heroku-redis:mini
heroku config:set TOKEN_STORE=redis
```

Benefits:
- Persistent token storage across deployments
- Shared token cache for horizontal scaling
- Support for multiple NationBuilder instances
- Automatic token refresh across server restarts

## Security Considerations

- **PKCE**: Prevents authorization code interception attacks
- **State Parameter**: CSRF protection for OAuth flow
- **Session Security**: Secure, httponly cookies in production
- **Token Handling**: No client-side exposure, automatic refresh
- **Error Handling**: Failed authentication clears session

## Troubleshooting

### Common Issues

**Redirect URI Mismatch**
- Ensure exact match between NationBuilder OAuth app and `NB_REDIRECT_URI`
- Check for trailing slashes and protocol (http vs https)

**Invalid State Parameter**
- Usually indicates session corruption or CSRF attack
- Clear browser cookies and retry
- Verify `SESSION_SECRET` is consistent

**Token Refresh Failures**
- Verify OAuth app has refresh token scope enabled
- Check `NB_CLIENT_SECRET` accuracy
- Ensure refresh token hasn't been revoked

**API 404 Errors**
- Confirm `NB_BASE_URL` uses correct nation slug
- Verify NationBuilder account has API access enabled
- Check that `/api/v2/signups/me` endpoint is available

## Development

### Testing OAuth Flow

1. Start application: `ruby app.rb`
2. Visit `http://localhost:4567`
3. Click "Connect to NationBuilder"
4. Complete authorization on NationBuilder
5. Verify redirect to `/status` with connection details

### Extending Functionality

- **Additional API Endpoints**: Add methods to `NbApi` class
- **Webhook Handling**: Implement webhook receiver routes
- **Database Storage**: Replace MemoryStore with database-backed implementation
- **Multi-tenant Support**: Extend token storage for multiple organizations

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Security

Report security issues to [SECURITY.md](SECURITY.md).