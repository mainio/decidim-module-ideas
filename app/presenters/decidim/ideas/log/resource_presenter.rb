# frozen_string_literal: true

module Decidim
  module Ideas
    module Log
      class ResourcePresenter < Decidim::Log::ResourcePresenter
        private

        # Private: Presents resource name.
        #
        # Returns an HTML-safe String.
        def present_resource_name
          if resource.present?
            Decidim::Ideas::IdeaPresenter.new(resource).title
          else
            super
          end
        end
      end
    end
  end
end
