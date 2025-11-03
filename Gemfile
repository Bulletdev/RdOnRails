# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.1'
gem 'bootsnap', require: false
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rails', '~> 7.1', '>= 7.1.3.2'
gem 'tzinfo-data', platforms: %i[windows jruby]

gem 'redis', '~> 5.0', '>= 5.2.0' # (https://www.cvedetails.com/version/1749213/Redis-Redis-7.0.15.html)
gem 'sidekiq', '~> 7.2', '>= 7.2.4'
gem 'sidekiq-scheduler', '~> 5.0', '>= 5.0.3'

gem 'guard'
gem 'guard-livereload', require: false

# Code quality
gem 'rubocop', '~> 1.57', require: false
gem 'rubocop-rails', '~> 2.22', require: false
gem 'rubocop-rspec', '~> 2.25', require: false

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 6.1.0'
end

group :development do
end
