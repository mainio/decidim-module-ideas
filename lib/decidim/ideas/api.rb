# frozen_string_literal: true

module Decidim
  module Ideas
    autoload :IdeaInputFilter, "decidim/api/idea_input_filter"
    autoload :IdeaInputSort, "decidim/api/idea_input_sort"
    autoload :IdeaMutationType, "decidim/api/idea_mutation_type"
    autoload :IdeaType, "decidim/api/idea_type"
    autoload :IdeaVersionType, "decidim/api/idea_version_type"
    autoload :IdeasType, "decidim/api/ideas_type"

    # separated context
    autoload :ResourceLinkSubject, "decidim/ideas/api/resource_link_subject"

    module ContentMutation
      autoload :FieldIdeasAttributes, "decidim/api/content_mutation/field_ideas_attributes"
    end

    module SectionContent
      autoload :LinkIdeasType, "decidim/api/section_content/link_ideas_type"
    end
  end
end
