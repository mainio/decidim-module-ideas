# frozen_string_literal: true

require "decidim/dev/common_rake"

def install_module(path)
  Dir.chdir(path) do
    system("bundle exec rails decidim_favorites:install:migrations")
    system("bundle exec rails decidim_feedback:install:migrations")
    system("bundle exec rails decidim_tags:install:migrations")
    system("bundle exec rails decidim_plans:install:migrations")
    system("bundle exec rails decidim_ideas:install:migrations")
    system("bundle exec rails db:migrate")
  end
end

def seed_db(path)
  Dir.chdir(path) do
    system("bundle exec rake db:seed")
  end
end

desc "Generates a dummy app for testing"
task test_app: "decidim:generate_external_test_app" do
  ENV["RAILS_ENV"] = "test"
  install_module("spec/decidim_dummy_app")
end

desc "Generates a development app"
task :development_app do
  Bundler.with_original_env do
    generate_decidim_app(
      "development_app",
      "--app_name",
      "#{base_app_name}_development_app",
      "--path",
      "..",
      "--recreate_db",
      "--demo"
    )
  end

  install_module("development_app")
  Dir.chdir("development_app") { system("bundle exec rails assets:precompile") }
  seed_db("development_app")
end
