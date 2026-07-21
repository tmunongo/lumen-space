source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.1'

gem 'rails', '~> 8.1'
gem 'sprockets-rails'
gem 'sqlite3', '~> 2.0'
gem 'puma', '>= 5.0'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder'
gem 'bootsnap', require: false

# Web scraping
gem 'nokogiri'
gem 'httparty'

# Markdown rendering
gem 'redcarpet'

# Image processing for uploads
gem 'image_processing', '~> 1.2'

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
end
