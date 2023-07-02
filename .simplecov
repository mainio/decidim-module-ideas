# frozen_string_literal: true

SimpleCov.start do
  root ENV.fetch("ENGINE_ROOT", nil)

  add_filter "lib/decidim/ideas/version.rb"
  add_filter "/spec"
  add_filter "lib/decidim/ideas/idea_seeder.rb"
end

SimpleCov.command_name ENV.fetch("COMMAND_NAME", nil) || File.basename(Dir.pwd)

SimpleCov.merge_timeout 1800
