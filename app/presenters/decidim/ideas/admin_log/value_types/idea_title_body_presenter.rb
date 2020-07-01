# frozen_string_literal: true

module Decidim
  module Ideas
    module AdminLog
      module ValueTypes
        class IdeaTitleBodyPresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            renderer = Decidim::ContentRenderers::HashtagRenderer.new(value)
            renderer.render(links: false).html_safe
          end
        end
      end
    end
  end
end
