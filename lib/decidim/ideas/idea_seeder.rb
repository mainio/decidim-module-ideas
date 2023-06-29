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
          # If the given locale is not in the Faker's available locales, those
          # translations will not be loaded
          I18n.available_locales << locale
          I18n.reload!
        end

        if authors.blank? || authors.is_a?(Integer)
          authors_amount = begin
            if authors.is_a?(Integer)
              authors
            else
              10
            end
          end
          authors_amount = amount if authors_amount > amount

          # Create a dummy authors if they are not provided
          @authors = Array.new(authors_amount) do |_i|
            author = Decidim::User.find_or_initialize_by(
              email: Faker::Internet.email
            )
            author.update!(
              password: "decidim123456789",
              password_confirmation: "decidim123456789",
              name: Faker::Name.name,
              nickname: Faker::Twitter.unique.screen_name,
              organization: component.organization,
              tos_agreement: "1",
              confirmed_at: Time.current
            )
            author
          end
        end

        # if component.settings.area_scope_parent_id
        #   parent_scope = Decidim::Scope.find(
        #     component.settings.area_scope_parent_id
        #   )
        # end

        amount.times do
          # coordinates = dummy_coordinates

          idea = Idea.new(idea_params.merge(
                            published_at: Time.current
                          ))
          idea.add_coauthor(authors.sample)
          idea.save!

          if Faker::Boolean.boolean
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
          component: component,
          title: Faker::Lorem.sentence(word_count: 2),
          body: Faker::Lorem.paragraphs(number: 2).join("\n"),
          category: component.participatory_space.categories.sample
        }
        params[:area_scope] = parent_scope.children.sample if parent_scope
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

      def parent_scope
        if component.settings.area_scope_parent_id
          @parent_scope ||= Decidim::Scope.find(
            component.settings.area_scope_parent_id
          )
        end
      end

      def dummy_address
        fake_with_locale do
          # With some locales Faker::Address.street_address returns addresses
          # where there is no space between the street name and building number
          "#{Faker::Address.street_name} #{Faker::Address.building_number}"
        end
      end

      def dummy_coordinates
        if bbox
          [rand(bbox[0][0]...bbox[1][0]), rand(bbox[0][1]...bbox[1][1])]
        else
          [Faker::Address.latitude, Faker::Address.longitude]
        end
      end

      def fake_with_locale
        if locale
          Faker::Address.with_locale(locale) { yield }
        else
          yield
        end
      end
    end
  end
end
