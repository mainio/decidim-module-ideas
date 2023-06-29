# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/ideas/version"

DECIDIM_VERSION = Decidim::Ideas.decidim_version

gem "decidim", DECIDIM_VERSION
gem "decidim-ideas", path: "."

gem "decidim-favorites", github: "mainio/decidim-module-favorites", branch: "release/0.25-stable"
gem "decidim-feedback", github: "mainio/decidim-module-feedback", branch: "release/0.25-stable"

gem "bootsnap", "~> 1.4"
gem "puma", ">= 5.5.1"

gem "faker", "~> 2.14"

# Lock Geocoder temporarily to 1.7 due to this issue:
# https://github.com/decidim/decidim/pull/9470
gem "geocoder", "~> 1.7.5"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION
  gem "decidim-plans", github: "mainio/decidim-module-plans", branch: "develop"
  gem "decidim-tags", github: "mainio/decidim-module-tags", branch: "release/0.25-stable"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "rubocop-faker"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 4.0.4"
end

group :test do
  gem "codecov", require: false
end
