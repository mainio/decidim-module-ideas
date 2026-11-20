# frozen_string_literal: true

require "decidim/ideas/version"
require "decidim/ideas/engine"
require "decidim/ideas/admin"
require "decidim/ideas/admin_engine"
require "decidim/ideas/component_settings_extensions"
require "decidim/ideas/component"
require "decidim/ideas/api"
require "acts_as_list"
require "decidim/favorites"

module Decidim
  module Ideas
    autoload :CommentableIdea, "decidim/ideas/commentable_idea"
    autoload :FormBuilder, "decidim/ideas/form_builder"
    autoload :FormBuilderDisabled, "decidim/ideas/form_builder_disabled"
    autoload :IdeaSerializer, "decidim/ideas/idea_serializer"
    autoload :MutationExtensions, "decidim/ideas/mutation_extensions"
    autoload :Seeds, "decidim/ideas/seeds"

    mattr_accessor :similarity_threshold, default: 0.25
    mattr_accessor :similarity_limit, default: 10
    mattr_accessor :participatory_space_highlighted_ideas_limit, default: 4
    mattr_accessor :process_group_highlighted_ideas_limit, default: 3
  end

  module ContentParsers
    autoload :IdeaParser, "decidim/content_parsers/idea_parser"
  end

  module ContentRenderers
    autoload :IdeaRenderer, "decidim/content_renderers/idea_renderer"
  end
end
