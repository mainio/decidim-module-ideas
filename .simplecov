# frozen_string_literal: true

SimpleCov.start do
  root ENV["ENGINE_ROOT"]

  add_filter "lib/decidim/ideas/version.rb"
  add_filter "/spec"
  add_filter "lib/decidim/ideas/idea_seeder.rb"
end

SimpleCov.command_name ENV["COMMAND_NAME"] || File.basename(Dir.pwd)

SimpleCov.merge_timeout 1800
