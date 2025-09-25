# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

### How to Report

1. **Do NOT** create a public GitHub issue
2. Email the maintainers directly with details of the vulnerability
3. Include steps to reproduce the issue
4. Provide your contact information for follow-up

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)
- Your contact information

### Response Timeline

- We will acknowledge receipt within 48 hours
- We will provide a detailed response within 7 days
- We will keep you updated on our progress

## Security Best Practices

### For Users

- Always use HTTPS in production
- Keep your dependencies updated
- Use strong, unique session secrets
- Regularly rotate your OAuth client secrets
- Monitor your NationBuilder API usage

### For Developers

- Never commit secrets or credentials to version control
- Use environment variables for all sensitive configuration
- Implement proper session security (secure, httponly, same_site)
- Validate all user inputs
- Use HTTPS for all OAuth redirects

## Security Considerations

### OAuth Security

- This application uses PKCE (Proof Key for Code Exchange) for enhanced security
- State parameters are used to prevent CSRF attacks
- Tokens are stored securely and never exposed to client-side code
- Automatic token refresh prevents token leakage

### Session Security

- Sessions use secure, httponly cookies in production
- Session secrets should be cryptographically strong
- Sessions are cleared on logout

### API Security

- All API calls use Bearer token authentication
- Tokens are automatically refreshed when needed
- Failed authentication clears the session

## Known Security Limitations

- Token storage is currently in-memory (not persistent)
- No rate limiting is implemented
- No input validation beyond OAuth parameters
- No audit logging for security events

## Updates

This security policy will be updated as needed. Please check back periodically for changes.