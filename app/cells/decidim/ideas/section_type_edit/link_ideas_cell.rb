# frozen_string_literal: true

module Decidim
  module Ideas
    module SectionTypeEdit
      class LinkIdeasCell < Decidim::Plans::SectionEditCell
        include Cell::ViewModel::Partial
        include Decidim::TranslatableAttributes

        delegate :current_participatory_space, :snippets, to: :controller

        def show
          # The component cannot be displayed in case there are no ideas
          # components in the same space.
          return unless ideas_component

          render
        end

        private

        def picker_label
          @picker_label ||= translated_attribute(section.body)
        end

        # This will find the first ideas component from the same space. It does
        # not matter which component it is in case there are multiple ideas
        # components in the same space. This will be used to get the route to
        # the ideas search path.
        def ideas_component
          @ideas_component ||= Decidim::Component.order(:weight).find_by(
            participatory_space: current_participatory_space,
            manifest_name: "ideas"
          )
        end
      end
    end
  end
end
