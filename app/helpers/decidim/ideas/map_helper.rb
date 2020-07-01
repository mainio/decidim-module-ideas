# frozen_string_literal: true

module Decidim
  module Ideas
    # This helper include some methods for rendering ideas dynamic maps.
    module MapHelper
      include Decidim::ApplicationHelper
      # Serialize a collection of geocoded ideas to be used by the dynamic map component
      #
      # geocoded_ideas - A collection of geocoded ideas
      def ideas_data_for_map(geocoded_ideas)
        geocoded_ideas.map do |idea|
          idea.slice(:latitude, :longitude, :address).merge(title: present(idea).title,
                                                            body: truncate(present(idea).body, length: 100),
                                                            icon: icon("ideas", width: 40, height: 70, remove_icon_class: true),
                                                            link: idea_path(idea))
        end
      end
    end
  end
end
