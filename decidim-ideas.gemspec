# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/ideas/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-ideas"
  spec.version = Decidim::Ideas::VERSION
  spec.authors = ["Antti Hukkanen"]
  spec.email = ["antti.hukkanen@mainiotech.fi"]

  spec.summary = "Provides a module for ideation phase to Decidim."
  spec.description = "This module provides an easier user experience to collect ideas in participatory processes."
  spec.homepage = "https://github.com/mainio/decidim-module-ideas"
  spec.license = "AGPL-3.0"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "LICENSE-AGPLv3.txt",
    "Rakefile",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "acts_as_list", "~> 0.9"
  spec.add_dependency "cells-erb", "~> 0.1.0"
  spec.add_dependency "cells-rails", "~> 0.0.9"
  spec.add_dependency "decidim-core", Decidim::Ideas::DECIDIM_VERSION
  spec.add_dependency "kaminari", "~> 1.2", ">= 1.2.1"
  spec.add_dependency "ransack", "~> 2.1.1"
  spec.add_dependency "social-share-button", "~> 1.2", ">= 1.2.1"

  # We need to lock the GraphQL gem to 1.9.x until the Decidim core type
  # definitions have been updated to the new GraphQL class based definitions.
  spec.add_dependency "graphql", "~> 1.9.19"

  spec.add_development_dependency "decidim-dev", Decidim::Ideas::DECIDIM_VERSION
end
