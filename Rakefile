require 'bundler/setup'

desc "Run the application"
task :start do
  exec "ruby app.rb"
end

desc "Install dependencies"
task :install do
  exec "bundle install"
end

desc "Run tests (when implemented)"
task :test do
  puts "Tests not yet implemented"
end

desc "Start with Foreman"
task :foreman do
  exec "foreman start"
end

desc "Check environment variables"
task :check_env do
  require 'dotenv'
  Dotenv.load
  
  required_vars = %w[
    SESSION_SECRET
    NB_CLIENT_ID
    NB_REDIRECT_URI
    NB_BASE_URL
    NB_SCOPES
  ]
  
  missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }
  
  if missing_vars.empty?
    puts "✓ All required environment variables are set"
  else
    puts "✗ Missing environment variables:"
    missing_vars.each { |var| puts "  - #{var}" }
    puts "\nCopy .env.example to .env and fill in the values"
  end
end

desc "Show help"
task :help do
  puts "Available tasks:"
  puts "  rake start     - Run the application"
  puts "  rake install   - Install dependencies"
  puts "  rake foreman   - Start with Foreman"
  puts "  rake check_env - Check environment variables"
  puts "  rake test      - Run tests (not yet implemented)"
end

task default: :help