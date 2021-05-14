# frozen_string_literal: true

module Decidim
  module Ideas
    module SectionTypeEdit
      class LinkIdeasInlineCell < Decidim::Ideas::SectionTypeEdit::LinkIdeasCell
        def show
          # The component cannot be displayed in case there are no ideas
          # components in the same space.
          return unless ideas_component

          render
        end
      end
    end
  end
end
