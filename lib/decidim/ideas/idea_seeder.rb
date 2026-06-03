# frozen_string_literal: true

module Decidim
  module Ideas
    # This class seeds new ideas to the database using faker.
    class IdeaSeeder
      def initialize(component:, authors: nil, locale: nil, bbox: nil)
        @component = component
        @authors = authors
        @locale = locale
        @bbox = bbox
      end

      def seed!(amount: 5)
        raise "Please define a component" unless component

        original_locales = I18n.available_locales
        if locale
          I18n.available_locales << locale
          I18n.reload!
        end

        if authors.blank? || authors.is_a?(Integer)
          authors_amount = if authors.is_a?(Integer)
                             authors
                           else
                             10
                           end

          authors_amount = amount if authors_amount > amount

          @authors = Array.new(authors_amount) do |_i|
            author = Decidim::User.find_or_initialize_by(
              email: ::Faker::Internet.email
            )
            author.update!(
              password: "decidim123456789",
              password_confirmation: "decidim123456789",
              name: ::Faker::Name.name,
              nickname: ::Faker::X.unique.screen_name,
              organization: component.organization,
              tos_agreement: "1",
              confirmed_at: Time.current
            )
            author
          end
        end

        amount.times do
          idea = Idea.new(idea_params.merge(
                            published_at: Time.current
                          ))
          idea.add_coauthor(authors.sample)
          idea.save!

          assign_random_taxonomies(idea)

          if ::Faker::Boolean.boolean
            # Add versions to the idea
            rand(1..3).times do
              idea.update!(idea_params)
            end
          end

          yield idea if block_given?
        end
      ensure
        I18n.available_locales = original_locales
      end

      private

      attr_reader :component, :authors, :locale, :bbox

      def idea_params
        params = {
          component:,
          title: ::Faker::Lorem.sentence(word_count: 2),
          body: ::Faker::Lorem.paragraphs(number: 2).join("\n")
        }

        if component.settings.geocoding_enabled
          coordinates = dummy_coordinates
          params.merge!(
            address: dummy_address,
            latitude: coordinates[0],
            longitude: coordinates[1]
          )
        end

        params
      end

      def assign_random_taxonomies(idea)
        taxonomy_filters.each do |filter|
          assign_random_taxonomy_from_filter(idea, filter)
        end
      end

      def assign_random_taxonomy_from_filter(idea, filter)
        taxonomy_ids = filter.taxonomies.keys
        return if taxonomy_ids.empty?

        taxonomy_id = taxonomy_ids.sample
        idea.taxonomizations.find_or_create_by(taxonomy_id: taxonomy_id)
      end

      def taxonomy_filters
        @taxonomy_filters ||= begin
          filter_ids = component.settings.taxonomy_filters.map(&:to_i)
          Decidim::TaxonomyFilter.where(id: filter_ids)
        end
      end

      def dummy_address
        fake_with_locale do
          "#{::Faker::Address.street_name} #{::Faker::Address.building_number}"
        end
      end

      def dummy_coordinates
        if bbox
          [rand(bbox[0][0]...bbox[1][0]), rand(bbox[0][1]...bbox[1][1])]
        else
          [::Faker::Address.latitude, ::Faker::Address.longitude]
        end
      end

      def fake_with_locale
        if locale
          ::Faker::Address.with_locale(locale) { yield }
        else
          yield
        end
      end
    end
  end
end