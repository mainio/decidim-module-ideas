# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/participatory_processes/test/factories"

FactoryBot.define do
  factory :idea_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :ideas).i18n_name }
    manifest_name { :ideas }
    participatory_space { create(:participatory_process, :with_steps, organization: organization) }

    trait :with_idea_limit do
      transient do
        idea_limit { 1 }
      end

      settings do
        {
          idea_limit: idea_limit
        }
      end
    end

    trait :with_idea_length do
      transient do
        idea_length { 2000 }
      end

      settings do
        {
          idea_length: idea_length
        }
      end
    end

    trait :with_creation_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { creation_enabled: true }
        }
      end
    end

    trait :with_geocoding_enabled do
      settings do
        {
          geocoding_enabled: true
        }
      end
    end

    trait :with_attachments_allowed do
      settings do
        {
          attachments_allowed: true
        }
      end
    end

    trait :with_threshold_per_idea do
      transient do
        threshold_per_idea { 1 }
      end

      settings do
        {
          threshold_per_idea: threshold_per_idea
        }
      end
    end

    trait :with_can_accumulate_supports_beyond_threshold do
      settings do
        {
          can_accumulate_supports_beyond_threshold: true
        }
      end
    end

    trait :with_amendments_enabled do
      settings do
        {
          amendments_enabled: true
        }
      end
    end

    trait :with_comments_disabled do
      settings do
        {
          comments_enabled: false
        }
      end
    end

    trait :with_card_image_allowed do
      settings do
        {
          allow_image: true
        }
      end
    end

    trait :with_extra_hashtags do
      transient do
        automatic_hashtags { "AutoHashtag AnotherAutoHashtag" }
        suggested_hashtags { "SuggestedHashtag AnotherSuggestedHashtag" }
      end

      step_settings do
        {
          participatory_space.active_step.id => {
            automatic_hashtags: automatic_hashtags,
            suggested_hashtags: suggested_hashtags,
            creation_enabled: true
          }
        }
      end
    end

    trait :without_publish_answers_immediately do
      step_settings do
        {
          participatory_space.active_step.id => {
            publish_answers_immediately: false
          }
        }
      end
    end
  end

  factory :area_scope_parent, class: "Decidim::Scope" do
    name { Decidim::Faker::Localized.literal(generate(:scope_name)) }
    code { generate(:scope_code) }
    scope_type { create(:scope_type, organization: organization) }
    organization { parent ? parent.organization : build(:organization) }

    after :create do |area_scope|
      create_list(:subscope, 5, parent: area_scope)
    end
  end

  factory :idea, class: "Decidim::Ideas::Idea" do
    transient do
      users { nil }
      # user_groups correspondence to users is by sorting order
      user_groups { [] }
      skip_injection { false }
      area_scope_parent { create(:area_scope_parent, organization: component&.organization) }
    end

    title do
      content = generate(:title).dup
      content.prepend("<script>alert('TITLE');</script> ") unless skip_injection
      content
    end
    body do
      content = Faker::Lorem.sentences(number: 3).join("\n")
      content.prepend("<script>alert('BODY');</script> ") unless skip_injection
      content
    end
    component { create(:idea_component) }
    published_at { Time.current }
    address { "#{Faker::Address.street_name}, #{Faker::Address.city}" }

    after(:build) do |idea, evaluator|
      if idea.component
        users = evaluator.users || [create(:user, organization: idea.component.participatory_space.organization)]
        users.each_with_index do |user, idx|
          user_group = evaluator.user_groups[idx]
          idea.coauthorships.build(author: user, user_group: user_group)
        end

        idea.category = create(:category, participatory_space: idea.component.participatory_space) if idea.category.blank? && idea.category != false
      end

      idea.area_scope = evaluator.area_scope_parent.children.sample if idea.area_scope.blank? && idea.area_scope != false
    end

    trait :published do
      published_at { Time.current }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :evaluating do
      state { "evaluating" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :accepted do
      state { "accepted" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :rejected do
      state { "rejected" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :withdrawn do
      state { "withdrawn" }
    end

    trait :accepted_not_published do
      state { "accepted" }
      answered_at { Time.current }
      state_published_at { nil }
      answer { generate_localized_title }
    end

    trait :geocoded do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
    end

    trait :with_answer do
      state { "accepted" }
      answer { generate_localized_title }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :not_answered do
      state { nil }
    end

    trait :draft do
      published_at { nil }
    end

    trait :hidden do
      after :create do |idea|
        create(:moderation, hidden_at: Time.current, reportable: idea)
      end
    end

    trait :with_amendments do
      after :create do |idea|
        create_list(:idea_amendment, 5, amendable: idea)
      end
    end

    trait :with_photo do
      after :create do |idea|
        idea.attachments << create(:ideas_attachment, :with_image, attached_to: idea)
      end
    end

    trait :with_document do
      after :create do |idea|
        idea.attachments << create(:ideas_attachment, :with_pdf, attached_to: idea)
      end
    end
  end

  factory :idea_amendment, class: "Decidim::Amendment" do
    amendable { build(:idea) }
    emendation { build(:idea, component: amendable.component) }
    amender { build(:user, organization: amendable.component.participatory_space.organization) }
    state { Decidim::Amendment::STATES.sample }
  end

  factory :ideas_attachment, class: "Decidim::Ideas::Attachment" do
    title { generate_localized_title }
    description { Decidim::Faker::Localized.wrapped("<p>", "</p>") { generate_localized_title } }
    weight { 0 }
    attached_to { build(:participatory_process) }
    content_type { "image/jpeg" }
    file { Decidim::Dev.test_file("city.jpeg", "image/jpeg") } # Keep after attached_to
    file_size { 108_908 }

    trait :with_image do
      file { Decidim::Dev.test_file("city.jpeg", "image/jpeg") }
    end

    trait :with_pdf do
      weight { rand(1..9) }
      file { Decidim::Dev.test_file("Exampledocument.pdf", "application/pdf") }
      content_type { "application/pdf" }
      file_size { 17_525 }
    end
  end
end
