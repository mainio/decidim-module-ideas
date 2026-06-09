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

    system("npm i '@tarekraafat/autocomplete.js@<=10.2.7'")
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
    ENV["DEV_APP_GENERATION"] = "true"

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
  seed_db("development_app")
end

desc "Migrate area_scope_coordinates and area_scope_parent_id to taxonomy equivalents"
task migrate_area_coordinates: :environment do
  updated = 0

  Decidim::Component.where(manifest_name: "ideas").find_each do |component|
    settings = component.attributes["settings"]["global"] || {}
    old_parent_id = settings["area_scope_parent_id"]
    coordinates = settings["area_scope_coordinates"]

    next if old_parent_id.blank? && coordinates.blank?

    organization = component.organization

    # Migrate area_scope_parent_id to area_taxonomy_filter_id
    if old_parent_id.present?
      scope = defined?(Decidim::Scope) ? Decidim::Scope.find_by(id: old_parent_id) : nil

      unless scope
        puts "  WARNING: Scope #{old_parent_id} not found, cannot auto-migrate area_taxonomy_filter_id"
        settings.delete("area_scope_parent_id")
        next
      end

      taxonomy = Decidim::Taxonomy
                 .where(decidim_organization_id: organization.id)
                 .find { |t| t.name == scope.name }

      unless taxonomy
        puts "  WARNING: No taxonomy match for scope #{old_parent_id} (#{scope.name})"
        settings.delete("area_scope_parent_id")
        next
      end

      filter = Decidim::TaxonomyFilter.find_by(root_taxonomy_id: taxonomy.id) ||
               Decidim::TaxonomyFilter.find_by(root_taxonomy_id: taxonomy.parent_id)

      if filter
        settings["area_taxonomy_filter_id"] = filter.id
        puts "  Mapped area_scope_parent_id #{old_parent_id} => area_taxonomy_filter_id #{filter.id}"
      else
        puts "  WARNING: No TaxonomyFilter found for scope #{old_parent_id} (#{scope.name})"
      end

      settings.delete("area_scope_parent_id")
    end

    # Migrate area_scope_coordinates keys
    if coordinates.present?
      new_coordinates = {}
      coordinates.each do |old_id, coords|
        next if coords.blank?

        scope = Decidim::Scope.find_by(id: old_id) if defined?(Decidim::Scope)

        if scope
          taxonomy = Decidim::Taxonomy
                     .where(decidim_organization_id: organization.id)
                     .find { |t| t.name == scope.name }

          if taxonomy
            new_coordinates[taxonomy.id.to_s] = coords
            puts "  Mapped coordinate scope #{old_id} => taxonomy #{taxonomy.id}"
          else
            puts "  WARNING: No taxonomy match for coordinate scope #{old_id}"
            new_coordinates[old_id] = coords
          end
        elsif Decidim::Taxonomy.exists?(id: old_id)
          new_coordinates[old_id] = coords
          puts "  ID #{old_id} is already a taxonomy ID, keeping as is"
        else
          puts "  WARNING: Cannot resolve coordinate ID #{old_id}, keeping as is"
          new_coordinates[old_id] = coords
        end
      end

      settings["area_scope_coordinates"] = new_coordinates
    end

    component.update!(settings: component.attributes["settings"].merge("global" => settings))
    updated += 1
    puts "Updated component #{component.id}"
  end

  puts "Done. Updated #{updated} components."
end
