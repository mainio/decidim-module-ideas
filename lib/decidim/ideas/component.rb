# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:ideas) do |component|
  component.engine = Decidim::Ideas::Engine
  component.admin_engine = Decidim::Ideas::AdminEngine
  component.icon = "decidim/ideas/icon.svg"
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
    settings.attribute :area_scope_parent_id, type: :idea_area_scope, default: nil
    settings.attribute :area_scope_coordinates, type: :idea_area_scope_coordinates, default: {}
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :idea_listing_intro, type: :text, translated: true, editor: true
    settings.attribute :new_idea_help_text, type: :text, translated: true, editor: true
    settings.attribute :materials_text, type: :text, translated: true, editor: true
    settings.attribute :terms_intro, type: :string, translated: true
    settings.attribute :terms_text, type: :text, translated: true, editor: true
    settings.attribute :areas_info_intro, type: :string, translated: true
    settings.attribute :areas_info_text, type: :text, translated: true, editor: true
    settings.attribute :categories_info_intro, type: :string, translated: true
    settings.attribute :categories_info_text, type: :text, translated: true, editor: true
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
                          .includes(:category, :component, :area_scope)
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
    admin_user = Decidim::User.find_by(
      organization: participatory_space.organization,
      email: "admin@example.org"
    )

    step_settings = if participatory_space.allows_steps?
                      {
                        participatory_space.active_step.id => {
                          creation_enabled: true
                        }
                      }
                    else
                      {}
                    end

    # if participatory_space.scope
    #   scopes = participatory_space.scope.descendants
    #   global = participatory_space.scope
    # else
    #   scopes = participatory_space.organization.scopes
    #   global = nil
    # end

    areas = []
    area_type = Decidim::ScopeType.find_or_create_by(
      name: Decidim::Faker::Localized.literal("district"),
      plural: Decidim::Faker::Localized.literal("districts"),
      organization: participatory_space.organization
    )
    area_parent = Decidim::Scope.find_by(scope_type: area_type)
    if area_parent
      areas = area_parent.descendants
    else
      area_parent = Decidim::Scope.create!(
        name: Decidim::Faker::Localized.literal(Faker::Address.unique.city),
        code: Faker::Address.city.gsub(/\s/, "").upcase,
        scope_type: area_type,
        organization: participatory_space.organization
      )
      10.times do
        areas << Decidim::Scope.create!(
          name: Decidim::Faker::Localized.literal(Faker::Address.unique.community),
          code: "#{area_parent.code}-#{Faker::Address.unique.postcode}",
          scope_type: area_type,
          organization: participatory_space.organization,
          parent: area_parent
        )
      end
    end

    params = {
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :ideas).i18n_name,
      manifest_name: :ideas,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        area_scope_parent_id: area_parent.id
      },
      step_settings: step_settings
    }

    component = Decidim.traceability.perform_action!(
      "publish",
      Decidim::Component,
      admin_user,
      visibility: "all"
    ) do
      Decidim::Component.create!(params)
    end

    5.times do |n|
      state, answer, state_published_at = if n > 3
                                            ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), Time.current]
                                          elsif n > 2
                                            ["rejected", nil, Time.current]
                                          elsif n > 1
                                            ["evaluating", nil, Time.current]
                                          elsif n.positive?
                                            ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), nil]
                                          else
                                            [nil, nil, nil]
                                          end

      params = {
        component: component,
        category: participatory_space.categories.sample,
        area_scope: Faker::Boolean.boolean(true_ratio: 0.5) ? nil : areas.sample,
        title: Faker::Lorem.sentence(word_count: 2),
        body: Faker::Lorem.paragraphs(number: 2).join("\n"),
        state: state,
        answer: answer,
        answered_at: state.present? ? Time.current : nil,
        state_published_at: state_published_at,
        published_at: Time.current
      }

      idea = Decidim.traceability.perform_action!(
        "publish",
        Decidim::Ideas::Idea,
        admin_user,
        visibility: "all"
      ) do
        idea = Decidim::Ideas::Idea.new(params)
        idea.add_coauthor(participatory_space.organization)
        idea.save!
        idea
      end

      if n.positive?
        Decidim::User.where(decidim_organization_id: participatory_space.decidim_organization_id).all.sample(n).each do |author|
          user_group = [true, false].sample ? Decidim::UserGroups::ManageableUserGroups.for(author).verified.sample : nil
          idea.add_coauthor(author, user_group: user_group)
        end
      end

      if idea.state.nil?
        email = "amendment-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-amend#{n}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} amend#{n}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "decidim123456789",
          password_confirmation: "decidim123456789",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        group = Decidim::UserGroup.create!(
          name: Faker::Name.name,
          nickname: Faker::Twitter.unique.screen_name,
          email: Faker::Internet.email,
          extended_data: {
            document_number: Faker::Code.isbn,
            phone: Faker::PhoneNumber.phone_number,
            verified_at: Time.current
          },
          decidim_organization_id: component.organization.id,
          confirmed_at: Time.current
        )

        Decidim::UserGroupMembership.create!(
          user: author,
          role: "creator",
          user_group: group
        )

        params = {
          component: component,
          category: participatory_space.categories.sample,
          area_scope: Faker::Boolean.boolean(true_ratio: 0.5) ? nil : areas.sample,
          title: "#{idea.title} #{Faker::Lorem.sentence(word_count: 1)}",
          body: "#{idea.body} #{Faker::Lorem.sentence(word_count: 3)}",
          state: "evaluating",
          answer: nil,
          answered_at: Time.current,
          published_at: Time.current
        }

        emendation = Decidim.traceability.perform_action!(
          "create",
          Decidim::Ideas::Idea,
          author,
          visibility: "public-only"
        ) do
          emendation = Decidim::Ideas::Idea.new(params)
          emendation.add_coauthor(author, user_group: author.user_groups.first)
          emendation.save!
          emendation
        end

        Decidim::Amendment.create!(
          amender: author,
          amendable: idea,
          emendation: emendation,
          state: "evaluating"
        )
      end

      (n % 3).times do |m|
        email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "decidim123456789",
          password_confirmation: "decidim123456789",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current,
          personal_url: Faker::Internet.url,
          about: Faker::Lorem.paragraph(sentence_count: 2)
        )
      end

      Decidim::Comments::Seed.comments_for(idea)
    end
  end
end
