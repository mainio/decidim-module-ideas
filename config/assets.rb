# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

# Register the additonal path for Webpacker in order to make the module's
# stylesheets available for inclusion.
Decidim::Webpacker.register_path("#{base_path}/app/packs")

# Register the entrypoints for your module. These entrypoints can be included
# within your application using `javascript_pack_tag` and if you include any
# SCSS files within the entrypoints, they become available for inclusion using
# `stylesheet_pack_tag`.
Decidim::Webpacker.register_entrypoints(
  decidim_ideas: "#{base_path}/app/packs/entrypoints/decidim_ideas.js",
  decidim_ideas_idea_form: "#{base_path}/app/packs/entrypoints/decidim_ideas_idea_form.js",
  decidim_ideas_idea_picker_inline: "#{base_path}/app/packs/entrypoints/decidim_ideas_idea_picker_inline.js",
  decidim_ideas_idea_picker: "#{base_path}/app/packs/entrypoints/decidim_ideas_idea_picker.js",
  decidim_ideas_ideas_list: "#{base_path}/app/packs/entrypoints/decidim_ideas_ideas_list.js",
  decidim_ideas_map: "#{base_path}/app/packs/entrypoints/decidim_ideas_map.js",
  decidim_ideas_admin_component_settings: "#{base_path}/app/packs/entrypoints/decidim_ideas_admin_component_settings.js",
  decidim_ideas_admin_ideas_form: "#{base_path}/app/packs/entrypoints/decidim_ideas_admin_ideas_form.js",
  decidim_ideas_admin_ideas: "#{base_path}/app/packs/entrypoints/decidim_ideas_admin_ideas.js"
)

# Register the main application's stylesheet include statement
# Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/ideas/ideas")
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/ideas/ideas/_map")
