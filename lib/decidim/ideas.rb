# frozen_string_literal: true

require_relative "ideas/version"
require_relative "ideas/engine"
require_relative "ideas/admin"
require_relative "ideas/admin_engine"
require_relative "ideas/component_settings_extensions"
require_relative "ideas/component"
require "acts_as_list"
require "decidim/favorites"

module Decidim
  module Ideas
    autoload :CommentableIdea, "decidim/ideas/commentable_idea"
    autoload :FormBuilder, "decidim/ideas/form_builder"
    autoload :FormBuilderDisabled, "decidim/ideas/form_builder_disabled"
    autoload :IdeaSerializer, "decidim/ideas/idea_serializer"
    autoload :MutationExtensions, "decidim/ideas/mutation_extensions"

    include ActiveSupport::Configurable

    # Public Setting that defines the similarity minimum value to consider two
    # ideas similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar ideas will be shown.
    # Defaults to 10.
    config_accessor :similarity_limit do
      10
    end

    # Public Setting that defines how many ideas will be shown in the
    # participatory_space_highlighted_elements view hook
    config_accessor :participatory_space_highlighted_ideas_limit do
      4
    end

    # Public Setting that defines how many ideas will be shown in the
    # process_group_highlighted_elements view hook
    config_accessor :process_group_highlighted_ideas_limit do
      3
    end
  end

  module ContentParsers
    autoload :IdeaParser, "decidim/content_parsers/idea_parser"
  end

  module ContentRenderers
    autoload :IdeaRenderer, "decidim/content_renderers/idea_renderer"
  end
end
