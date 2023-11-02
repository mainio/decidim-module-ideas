# frozen_string_literal: true

require "decidim/dev"
# TODO: remove this part after finished
require 'simplecov'
SimpleCov.start do
  # `ENGINE_ROOT` holds the name of the engine we are testing.
  # This brings us to the main Decidim folder.
  root ENV.fetch("ENGINE_ROOT", nil)

  # We make sure we track all Ruby files, to avoid skipping unrequired files
  # We need to include the `../` section, otherwise it only tracks files from the
  # `ENGINE_ROOT` folder for some reason.
  track_files "**/*.rb"

  # We ignore some of the files because they are never tested
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"
  add_filter "/spec/"
  add_filter "/test/"
  add_filter "/development_app/"
  add_filter %r{^/lib/decidim/[^/]*/engine.rb}
  add_filter %r{^/lib/decidim/[^/]*/admin_engine.rb}
  add_filter %r{^/lib/decidim/[^/]*/component.rb}
  add_filter %r{^/lib/decidim/[^/]*/participatory_space.rb}
end

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path =
  File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
