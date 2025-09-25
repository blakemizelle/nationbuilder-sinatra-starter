# NationBuilder Sinatra Starter

A minimal Sinatra application demonstrating NationBuilder OAuth 2.0 authentication with PKCE (Proof Key for Code Exchange) and a simple v2 API integration.

## Features

- **OAuth 2.0 Authorization Code flow with PKCE** - Secure authentication without exposing client secrets
- **Automatic token refresh** - Handles token expiration seamlessly
- **Secure token storage** - In-memory storage with Redis support ready
- **Simple NationBuilder v2 API integration** - Make authenticated API calls
- **Heroku-ready deployment** - Includes Procfile and configuration
- **12-factor app compliance** - Environment-based configuration

## Quickstart

### Prerequisites

- Ruby 3.2+
- Bundler
- A NationBuilder account with OAuth app configured

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/nationbuilder-sinatra-starter.git
   cd nationbuilder-sinatra-starter
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and fill in your NationBuilder OAuth credentials:
   ```env
   SESSION_SECRET=your-super-secret-session-key-here
   NB_CLIENT_ID=your-nationbuilder-client-id
   NB_CLIENT_SECRET=your-nationbuilder-client-secret
   NB_REDIRECT_URI=http://localhost:4567/oauth/callback
   NB_BASE_URL=https://YOUR-NATION-SLUG.nationbuilder.com
   NB_SCOPES=read write
   TOKEN_STORE=memory
   ```
   
   **Important**: Replace `YOUR-NATION-SLUG` with your actual NationBuilder nation slug (the subdomain of your NationBuilder site).

4. **Register an OAuth app in NationBuilder**
   - Go to your NationBuilder admin panel
   - Navigate to Settings → API
   - Create a new OAuth application
   - Set the redirect URI to `http://localhost:4567/oauth/callback`
   - Copy the Client ID and Client Secret to your `.env` file

5. **Run the application**
   ```bash
   ruby app.rb
   ```
   
   Or with Foreman (recommended):
   ```bash
   foreman start
   ```

6. **Visit the application**
   Open http://localhost:4567 in your browser and click "Connect to NationBuilder"

## How It Works

### OAuth Flow

1. User clicks "Connect to NationBuilder"
2. App generates PKCE code verifier and challenge
3. User is redirected to NationBuilder authorization page
4. User authorizes the application
5. NationBuilder redirects back with authorization code
6. App exchanges code for access and refresh tokens
7. Tokens are stored securely for future API calls

### Token Management

- Tokens are automatically refreshed when they expire or are close to expiring
- Failed refresh attempts clear the session and require re-authentication
- Tokens are never logged or exposed to client-side JavaScript

### File Structure

```
.
├── app.rb                 # Main Sinatra application
├── config.ru             # Rack configuration
├── Gemfile               # Ruby dependencies
├── Procfile              # Heroku deployment
├── .env.example          # Environment variables template
├── lib/
│   ├── oauth_client.rb   # OAuth 2.0 + PKCE implementation
│   ├── nb_api.rb         # NationBuilder API wrapper
│   └── token_store/
│       ├── token_store.rb    # Token storage interface
│       └── memory_store.rb   # In-memory implementation
└── views/
    ├── layout.erb        # Base template
    ├── index.erb         # Home page
    └── status.erb        # API status page
```

## Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SESSION_SECRET` | Secret key for session encryption | `your-super-secret-key` |
| `NB_CLIENT_ID` | NationBuilder OAuth client ID | `abc123...` |
| `NB_CLIENT_SECRET` | NationBuilder OAuth client secret | `def456...` |
| `NB_REDIRECT_URI` | OAuth callback URL | `http://localhost:4567/oauth/callback` |
| `NB_BASE_URL` | NationBuilder base URL | `https://YOUR-NATION-SLUG.nationbuilder.com` |
| `NB_SCOPES` | OAuth scopes | `read write` |
| `TOKEN_STORE` | Token storage backend | `memory` or `redis` |

### Optional Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection URL (for Redis token store) | `redis://localhost:6379/0` |

## Deploy to Heroku

1. **Create a Heroku app**
   ```bash
   heroku create your-app-name
   ```

2. **Set environment variables**
   ```bash
   heroku config:set SESSION_SECRET=your-production-secret-key
   heroku config:set NB_CLIENT_ID=your-client-id
   heroku config:set NB_CLIENT_SECRET=your-client-secret
   heroku config:set NB_REDIRECT_URI=https://your-app-name.herokuapp.com/oauth/callback
   heroku config:set NB_BASE_URL=https://YOUR-NATION-SLUG.nationbuilder.com
   heroku config:set NB_SCOPES=read write
   heroku config:set TOKEN_STORE=memory
   ```

3. **Update NationBuilder OAuth app**
   - Change the redirect URI to `https://your-app-name.herokuapp.com/oauth/callback`

4. **Deploy**
   ```bash
   git push heroku main
   ```

5. **Open your app**
   ```bash
   heroku open
   ```

## Routes

| Route | Method | Description |
|-------|--------|-------------|
| `/` | GET | Home page with connect button |
| `/login` | GET | Initiate OAuth flow |
| `/oauth/callback` | GET | OAuth callback handler |
| `/status` | GET | Show API data and token status |
| `/logout` | GET | Clear session and tokens |
| `/health` | GET | Health check endpoint |

## Production Deployment with Redis

For production use with multiple NationBuilder instances, use Redis for token storage:

### Heroku with Redis

1. **Add Heroku Redis addon**
   ```bash
   heroku addons:create heroku-redis:mini
   ```

2. **Set environment variables**
   ```bash
   heroku config:set TOKEN_STORE=redis
   # REDIS_URL is automatically set by Heroku Redis addon
   ```

3. **Deploy**
   ```bash
   git push heroku main
   ```

### Benefits of Redis Token Storage

- **Multi-instance support**: Multiple NationBuilder slugs can connect simultaneously
- **Persistent storage**: Tokens survive app restarts and deployments
- **Horizontal scaling**: Multiple app instances share token cache
- **Automated refresh**: Token refresh works across server restarts
- **Production ready**: Suitable for high-traffic applications

## Next Steps

- **Webhook Handling**: Add webhook receiver for real-time updates
- **Docker Support**: Add Dockerfile for containerized deployment
- **Testing**: Add RSpec tests for OAuth flow and API integration
- **Logging**: Add structured logging for production monitoring
- **Error Handling**: Enhance error handling and user feedback

## Troubleshooting

### Redirect URI Mismatch
- Ensure the redirect URI in your NationBuilder OAuth app matches exactly
- For local development: `http://localhost:4567/oauth/callback`
- For Heroku: `https://your-app-name.herokuapp.com/oauth/callback`

### Invalid State Parameter
- This usually indicates a CSRF attack or session issue
- Clear your browser cookies and try again
- Ensure `SESSION_SECRET` is set and consistent

### Token Refresh Failed
- Check that your OAuth app has refresh token scope enabled
- Verify `NB_CLIENT_SECRET` is correct
- Ensure the refresh token hasn't been revoked

### API Calls Failing
- Verify `NB_BASE_URL` is correct for your NationBuilder instance
- Check that the required scopes are granted
- Ensure your NationBuilder account has API access enabled
- Confirm you're using the v2 API endpoints (this app uses `/v2/me` and `/v2/sites/me`)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

For security concerns, please see [SECURITY.md](SECURITY.md).