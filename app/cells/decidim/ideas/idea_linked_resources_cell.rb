# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Ideas
    # This cell renders the linked resource of a idea.
    class IdeaLinkedResourcesCell < Decidim::ViewModel
      def show
        render if linked_resource
      end
    end
  end
end
