# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:ideas) do |component|
  component.engine = Decidim::Ideas::Engine
  component.admin_engine = Decidim::Ideas::AdminEngine
  component.icon = "media/images/decidim_ideas.svg"
  component.stylesheet = "decidim/ideas/ideas"

  component.on(:before_destroy) do |instance|
    raise "Can't destroy this component when there are ideas" if Decidim::Ideas::Idea.where(component: instance).any?
  end

  component.data_portable_entities = ["Decidim::Ideas::Idea"]
  component.newsletter_participant_entities = ["Decidim::Ideas::Idea"]
  component.actions = %w(create withdraw amend)
  component.query_type = "Decidim::Ideas::IdeasType"
  component.permissions_class_name = "Decidim::Ideas::Permissions"

  component.settings(:global) do |settings|
    settings.attribute :idea_limit, type: :integer, default: 0
    settings.attribute :idea_title_length, type: :integer, default: 150
    settings.attribute :idea_length, type: :integer, default: 1000
    settings.attribute :idea_edit_before_minutes, type: :integer, default: 60
    settings.attribute :threshold_per_idea, type: :integer, default: 0
    settings.attribute :can_accumulate_supports_beyond_threshold, type: :boolean, default: false
    settings.attribute :idea_answering_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :comments_max_length, type: :integer, default: 1000
    settings.attribute :image_allowed, type: :boolean, default: true
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
    settings.attribute :amendments_enabled, type: :boolean, default: false
    settings.attribute :amendments_wizard_help_text, type: :text, translated: true, editor: true, required: false
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :default_map_center_coordinates, type: :string
    settings.attribute :area_taxonomy_filter_id, type: :idea_area_taxonomy_filter
    settings.attribute :area_scope_coordinates, type: :idea_area_scope_coordinates, default: {}
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :idea_listing_intro, type: :text, translated: true, editor: true
    settings.attribute :new_idea_help_text, type: :text, translated: true, editor: true
    settings.attribute :materials_text, type: :text, translated: true, editor: true
    settings.attribute :terms_intro, type: :string, translated: true
    settings.attribute :terms_text, type: :text, translated: true, editor: true
    settings.attribute :taxonomy_filters, type: :taxonomy_filters
  end

  component.settings(:step) do |settings|
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :idea_answering_enabled, type: :boolean, default: true
    settings.attribute :publish_answers_immediately, type: :boolean, default: true
    settings.attribute :amendment_creation_enabled, type: :boolean, default: true
    settings.attribute :amendment_reaction_enabled, type: :boolean, default: true
    settings.attribute :amendment_promotion_enabled, type: :boolean, default: true
    settings.attribute :amendments_visibility,
                       type: :enum, default: "all",
                       choices: -> { Decidim.config.amendments_visibility_options }
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :automatic_hashtags, type: :text, editor: false, required: false
    settings.attribute :suggested_hashtags, type: :text, editor: false, required: false
  end

  component.register_resource(:idea) do |resource|
    resource.model_class_name = "Decidim::Ideas::Idea"
    resource.template = "decidim/ideas/ideas/linked_ideas"
    resource.card = "decidim/ideas/idea"
    resource.actions = %w(amend)
    resource.searchable = true
  end

  component.register_stat :ideas_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Ideas::FilteredIdeas.for(components, start_at, end_at)
                                 .only_amendables
                                 .published
                                 .except_withdrawn
                                 .not_hidden
                                 .count
  end

  component.register_stat :ideas_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Ideas::FilteredIdeas.for(components, start_at, end_at)
                                 .only_amendables
                                 .accepted
                                 .not_hidden
                                 .count
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    ideas = Decidim::Ideas::FilteredIdeas.for(components, start_at, end_at).only_amendables.published.not_hidden
    Decidim::Comments::Comment.where(root_commentable: ideas).count
  end

  component.register_stat :followers_count, tag: :followers, priority: Decidim::StatsRegistry::LOW_PRIORITY do |components, start_at, end_at|
    ideas_ids = Decidim::Ideas::FilteredIdeas.for(components, start_at, end_at).only_amendables.published.not_hidden.pluck(:id)
    Decidim::Follow.where(decidim_followable_type: "Decidim::Ideas::Idea", decidim_followable_id: ideas_ids).count
  end

  component.exports :ideas do |exports|
    exports.collection do |component_instance, _user|
      Decidim::Ideas::Idea.where(component: component_instance)
                          .only_amendables
                          .published
                          .not_hidden
                          .includes(:taxonomies, :component)
    end

    exports.include_in_open_data = true
    exports.serializer Decidim::Ideas::IdeaSerializer
  end

  component.exports :comments do |exports|
    exports.collection do |component_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::Ideas::Idea, component_instance
      )
    end

    exports.serializer Decidim::Comments::CommentSerializer
  end

  component.seeds do |participatory_space|
    Decidim::Ideas::Seeds.new(participatory_space:).call
  end
end
