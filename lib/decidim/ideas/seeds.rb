# frozen_string_literal: true

require "decidim/seeds"
require "decidim/ideas/idea_seeder"

module Decidim
  module Ideas
    class Seeds < Decidim::Seeds
      def initialize(participatory_space:)
        @participatory_space = participatory_space
      end

      def call
        step_settings = if participatory_space.allows_steps?
                          { participatory_space.active_step.id => { creation_enabled: true } }
                        else
                          {}
                        end

        # Create the area taxonomies and filter
        area_taxonomy = create_taxonomy!(name: "Areas", parent: nil)
        area_parent = create_taxonomy!(name: ::Faker::Address.unique.city, parent: area_taxonomy)
        areas = 10.times.map do
          create_taxonomy!(name: ::Faker::Address.unique.community, parent: area_parent)
        end
        area_filter = create_taxonomy_filter!(
          root_taxonomy: area_taxonomy,
          taxonomies: areas.sample(3)
        )

        # Create the category taxonomies and filter
        category_taxonomy = create_taxonomy!(name: "Categories", parent: nil)
        categories = 3.times.flat_map do
          sub_taxonomy = create_taxonomy!(name: ::Faker::Lorem.sentence(word_count: 5), parent: category_taxonomy)
          5.times.map do
            create_taxonomy!(name: ::Faker::Lorem.sentence(word_count: 5), parent: sub_taxonomy)
          end
        end
        category_filter = create_taxonomy_filter!(
          root_taxonomy: category_taxonomy,
          taxonomies: categories.sample(3)
        )

        # Component always uses category filter, 50% chance to include area filter
        selected_filters = [category_filter.id]
        selected_filters << area_filter.id if ::Faker::Boolean.boolean(true_ratio: 0.5)

        # Create the component
        component = Decidim.traceability.perform_action!(
          "publish",
          Decidim::Component,
          admin_user,
          visibility: "all"
        ) do
          Decidim::Component.create!(
            name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :ideas).i18n_name,
            manifest_name: :ideas,
            published_at: Time.current,
            participatory_space:,
            settings: { taxonomy_filters: selected_filters },
            step_settings:
          )
        end

        # Use IdeaSeeder to create the actual ideas
        Decidim::Ideas::IdeaSeeder.new(component:).seed!(amount: 5) do |idea|
          Decidim::Comments::Seed.comments_for(idea)
        end
      end

      private

      attr_reader :participatory_space

      def organization
        @organization ||= participatory_space.organization
      end
    end
  end
end
