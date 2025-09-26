# NationBuilder Sinatra Starter

A working example of how to connect to NationBuilder using OAuth 2.0 authentication. This app shows you how to securely log users into NationBuilder and make API calls to get their information.

## What This Does

This app demonstrates:
- **OAuth Login**: Users can connect their NationBuilder account
- **Secure Token Handling**: Automatically manages access tokens and refresh
- **API Integration**: Makes calls to NationBuilder's API to get user data
- **Multi-Tenant Support**: Handles multiple users from different NationBuilder instances
- **Production Ready**: Can be deployed to Heroku with Redis for scaling

## How It Works

1. User clicks "Connect to NationBuilder"
2. They're redirected to NationBuilder to authorize your app
3. NationBuilder sends them back with an authorization code
4. Your app exchanges that code for access tokens
5. You can now make API calls to get their NationBuilder data

The app uses PKCE (Proof Key for Code Exchange) for security, which is the modern standard for OAuth apps.

## Multi-Tenant Magic

**The app automatically supports multiple NationBuilder instances!** Here's the magic:

- **Automatic Detection**: When NationBuilder redirects users back, it includes a `nation` parameter (e.g., `nation=myorg`)
- **Per-User Storage**: Each user's tokens and nation URL are stored separately by session ID
- **Isolated API Calls**: Each user's API calls automatically go to their specific NationBuilder instance
- **No Configuration Needed**: Users don't need to enter their nation slug - it's detected automatically

**Example:**
- User from `myorg.nationbuilder.com` connects → API calls go to `https://myorg.nationbuilder.com/api/v2/signups/me`
- User from `anotherorg.nationbuilder.com` connects → API calls go to `https://anotherorg.nationbuilder.com/api/v2/signups/me`
- Both users can use the same app instance simultaneously!

## Quick Start

### 1. Get NationBuilder Credentials

First, you need to create an OAuth app in NationBuilder:

1. Go to your NationBuilder admin panel
2. Navigate to **Settings → API**
3. Click **"Create OAuth Application"**
4. Set the **Redirect URI** to: `http://localhost:4567/oauth/callback`
5. Copy the **Client ID** and **Client Secret**

### 2. Set Up the App

```bash
# Clone the repository
git clone https://github.com/blakemizelle/nationbuilder-sinatra-starter.git
cd nationbuilder-sinatra-starter

# Install dependencies
bundle install

# Copy the example environment file
cp .env.example .env
```

### 3. Configure Environment Variables

Edit the `.env` file with your NationBuilder credentials:

```env
# Session secret - use a random string
SESSION_SECRET=your-random-secret-key-here

# NationBuilder OAuth credentials
NB_CLIENT_ID=your-client-id-from-nationbuilder
NB_CLIENT_SECRET=your-client-secret-from-nationbuilder
NB_REDIRECT_URI=http://localhost:4567/oauth/callback
NB_BASE_URL=https://your-nation-slug.nationbuilder.com
NB_SCOPES=default

# Token storage (memory is fine for development)
TOKEN_STORE=memory
```

**Important**: Replace `your-nation-slug` with your actual NationBuilder subdomain (the part before `.nationbuilder.com` in your NationBuilder URL).

### 4. Run the App

```bash
ruby app.rb
```

Visit `http://localhost:4567` and click "Connect to NationBuilder" to test the OAuth flow.

## File Structure

```
nationbuilder-sinatra-starter/
├── app.rb                    # Main Sinatra application
├── config.ru                 # Rack configuration
├── Gemfile                   # Ruby dependencies
├── Procfile                  # Heroku deployment config
├── .env.example              # Environment variables template
├── lib/
│   ├── oauth_client.rb       # Handles OAuth flow
│   ├── nb_api.rb             # Makes API calls to NationBuilder
│   └── token_store/
│       ├── token_store.rb    # Interface for storing tokens
│       └── memory_store.rb   # Stores tokens in memory
└── views/
    ├── layout.erb            # Base HTML template
    ├── index.erb             # Home page
    └── status.erb            # Shows connection status
```

## Understanding the Code

### OAuth Flow (`lib/oauth_client.rb`)

This handles the OAuth authentication:
- Generates secure random codes for PKCE
- Builds the authorization URL
- Exchanges authorization codes for access tokens
- Handles token refresh when they expire

### API Client (`lib/nb_api.rb`)

This makes authenticated requests to NationBuilder:
- Adds Bearer tokens to API requests
- Automatically refreshes tokens when they expire
- Handles API errors gracefully

### Token Storage (`lib/token_store/`)

This manages where tokens are stored:
- **MemoryStore**: Stores tokens in memory (good for development)
- **RedisStore**: Stores tokens in Redis (good for production)

## Environment Variables Explained

| Variable | What It Does | Example |
|----------|--------------|---------|
| `SESSION_SECRET` | Encrypts user sessions | `my-super-secret-key` |
| `NB_CLIENT_ID` | Your NationBuilder app ID | `abc123...` |
| `NB_CLIENT_SECRET` | Your NationBuilder app secret | `def456...` |
| `NB_REDIRECT_URI` | Where NationBuilder sends users back | `http://localhost:4567/oauth/callback` |
| `NB_BASE_URL` | Your NationBuilder site URL | `https://myorg.nationbuilder.com` |
| `NB_SCOPES` | What permissions to request | `default` |
| `TOKEN_STORE` | How to store tokens | `memory` or `redis` |

## Routes

The app has these endpoints:

- **`/`** - Home page with connect button
- **`/login`** - Starts the OAuth flow
- **`/oauth/callback`** - Handles NationBuilder's response
- **`/status`** - Shows connection status and user info
- **`/logout`** - Clears the connection
- **`/health`** - Health check for monitoring

## Deploying to Heroku

### 1. Create Heroku App

```bash
heroku create your-app-name
```

### 2. Set Environment Variables

```bash
heroku config:set SESSION_SECRET=your-production-secret-key
heroku config:set NB_CLIENT_ID=your-client-id
heroku config:set NB_CLIENT_SECRET=your-client-secret
heroku config:set NB_REDIRECT_URI=https://your-app-name.herokuapp.com/oauth/callback
heroku config:set NB_BASE_URL=https://your-nation-slug.nationbuilder.com
heroku config:set NB_SCOPES=default
heroku config:set TOKEN_STORE=memory
```

### 3. Update NationBuilder

In your NationBuilder OAuth app settings, change the redirect URI to:
`https://your-app-name.herokuapp.com/oauth/callback`

### 4. Deploy

```bash
git push heroku main
heroku open
```

## Production Scaling with Redis

For production apps that need to handle multiple users or multiple NationBuilder instances:

### Add Redis to Heroku

```bash
heroku addons:create heroku-redis:mini
heroku config:set TOKEN_STORE=redis
```

This gives you:
- **Persistent storage**: Tokens survive app restarts
- **Multiple users**: Each user's tokens are stored separately
- **Multi-tenant support**: Users from different NationBuilder instances
- **Scaling**: Multiple app instances can share the same token store

### Multi-Tenant Architecture

With Redis enabled, the app becomes truly multi-tenant:

- **User A** from `org1.nationbuilder.com` → Stored in Redis with session ID
- **User B** from `org2.nationbuilder.com` → Stored in Redis with different session ID  
- **User C** from `org3.nationbuilder.com` → Stored in Redis with different session ID
- **All users** can connect simultaneously to the same app instance
- **Each user's** API calls go to their specific NationBuilder instance
- **Perfect for SaaS** applications serving multiple organizations

## Common Issues

### "Invalid redirect URI"

Make sure the redirect URI in your NationBuilder OAuth app exactly matches what you set in `NB_REDIRECT_URI`. Check for:
- `http` vs `https`
- Trailing slashes
- Port numbers

### "Invalid state parameter"

This usually means your session got corrupted. Try:
- Clearing your browser cookies
- Making sure `SESSION_SECRET` is set
- Restarting the app

### "Token refresh failed"

Check that:
- Your OAuth app has refresh token permissions enabled
- `NB_CLIENT_SECRET` is correct
- The refresh token hasn't been revoked

### API calls return 404

Verify that:
- `NB_BASE_URL` uses your correct NationBuilder subdomain (for fallback)
- Your NationBuilder account has API access enabled
- The `/api/v2/signups/me` endpoint is available
- The `nation` parameter is being passed correctly in the OAuth callback

**Note**: The app automatically detects the nation from the OAuth callback, so users don't need to manually enter their nation slug.

## Extending This App

### Adding More API Calls

To call other NationBuilder endpoints, add methods to `lib/nb_api.rb`:

```ruby
def get_people
  authenticated_request(method: 'GET', path: '/api/v2/people')
end
```

### Adding Webhooks
> Note: While the functionality remains in the application, NationBuilder has officially deprectaed support for webhooks as they can often be unreliable at scale

To receive webhooks from NationBuilder, add routes to `app.rb`:

```ruby
post '/webhook' do
  # Handle webhook data
  "OK"
end
```

### Using a Database

Replace the memory token store with a database-backed version for better persistence.

## Security Notes

- **PKCE**: Prevents authorization code interception
- **State Parameter**: Protects against CSRF attacks
- **Secure Sessions**: Uses secure cookies in production
- **Token Handling**: Never exposes tokens to the client side

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Official NationBuilder Documentation

For comprehensive information about NationBuilder's API and authentication:

- **[API Authentication Quick Start Guide](https://support.nationbuilder.com/en/articles/9180281-api-authentication-quick-start-guide)** - Official OAuth setup and authentication
- **[API v2 Walkthrough](https://support.nationbuilder.com/en/articles/9899245-api-v2-walkthrough)** - Complete guide to NationBuilder's v2 API
- **[Relationships between Resources in v2 API](https://support.nationbuilder.com/en/articles/9912495-relationships-between-resources-in-v2-api)** - Understanding data relationships and endpoints

## Getting Help

If you run into issues:
1. Check the troubleshooting section above
2. Review the official NationBuilder documentation above
3. Open an issue on GitHub with details about your problem
