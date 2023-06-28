# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/ideas/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-ideas"
  spec.version = Decidim::Ideas.version
  spec.authors = ["Antti Hukkanen"]
  spec.email = ["antti.hukkanen@mainiotech.fi"]

  spec.required_ruby_version = ">= 2.7"

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

  spec.add_dependency "decidim-core", Decidim::Ideas.decidim_version
  spec.add_dependency "decidim-favorites", Decidim::Ideas.decidim_version
  spec.add_dependency "decidim-feedback", Decidim::Ideas.decidim_version

  spec.add_development_dependency "decidim-dev", Decidim::Ideas.decidim_version
  spec.add_development_dependency "decidim-plans", Decidim::Ideas.decidim_version
  spec.add_development_dependency "decidim-tags", Decidim::Ideas.decidim_version
end
