# frozen_string_literal: true

module Decidim
  module Ideas
    # Exposes Ideas versions so users can see how an Idea has been updated
    # through time.
    class VersionsController < Decidim::Ideas::ApplicationController
      include Decidim::ApplicationHelper
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        @versioned_resource ||=
          present(Idea.where(component: current_component).find(params[:idea_id]))
      end
    end
  end
end
