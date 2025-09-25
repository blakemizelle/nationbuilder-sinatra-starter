# Contributing to NationBuilder Sinatra Starter

Thank you for your interest in contributing to the NationBuilder Sinatra Starter! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker to report bugs or request features
- Include as much detail as possible (Ruby version, error messages, steps to reproduce)
- Check existing issues before creating new ones

### Submitting Changes

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following the coding standards below
4. **Test your changes** locally
5. **Commit your changes** with clear, descriptive commit messages
6. **Push to your fork** and create a Pull Request

### Coding Standards

- Follow Ruby style guidelines (use RuboCop if available)
- Write clear, self-documenting code
- Add comments for complex logic
- Keep methods small and focused
- Use meaningful variable and method names

### Testing

- Test your changes locally before submitting
- Ensure the OAuth flow works end-to-end
- Test both success and error scenarios
- Verify Heroku deployment still works

### Documentation

- Update README.md if you add new features or change configuration
- Add comments to complex code sections
- Update the troubleshooting section if you fix common issues

## Development Setup

1. Clone your fork:
   ```bash
   git clone https://github.com/your-username/nationbuilder-sinatra-starter.git
   cd nationbuilder-sinatra-starter
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up environment:
   ```bash
   cp .env.example .env
   # Edit .env with your NationBuilder credentials
   ```

4. Run the application:
   ```bash
   ruby app.rb
   ```

## Pull Request Process

1. Ensure your PR has a clear title and description
2. Reference any related issues
3. Include screenshots for UI changes
4. Ensure all tests pass (if applicable)
5. Request review from maintainers

## Code of Conduct

Please note that this project follows a Code of Conduct. By participating, you agree to uphold this code.

## Questions?

If you have questions about contributing, please open an issue or contact the maintainers.