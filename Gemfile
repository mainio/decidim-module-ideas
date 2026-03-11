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

gem "decidim-favorites", github: "mainio/decidim-module-favorites", branch: "main"
gem "decidim-feedback", github: "mainio/decidim-module-feedback", branch: "main"

gem "bootsnap", "~> 1.4"
gem "faker", "~> 3.2.2"
gem "puma", ">= 5.6.2"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", DECIDIM_VERSION
  gem "decidim-plans", github: "mainio/decidim-module-plans", branch: "main"
  gem "decidim-tags", github: "mainio/decidim-module-tags", branch: "main"

  # Fix issue with simplecov-cobertura
  # See: https://github.com/jessebs/simplecov-cobertura/pull/44
  gem "rexml", "3.4.1"
end

group :development do
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "web-console", "~> 4.2"
end
