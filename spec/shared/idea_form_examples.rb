# frozen_string_literal: true

shared_examples "a idea form" do |options|
  subject { form }

  let(:organization) { create(:organization, tos_version: Time.current, available_locales: [:en]) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let(:title) do
    if options[:i18n] == false
      "More sidewalks and less roads!"
    else
      { en: "More sidewalks and less roads!" }
    end
  end
  let(:body) do
    if options[:i18n] == false
      "Everything would be better"
    else
      { en: "Everything would be better" }
    end
  end
  let(:author) { create(:user, :confirmed, organization:) }
  let(:user_group) { create(:user_group, :confirmed, :verified, users: [author], organization:) }
  let(:user_group_id) { user_group.id }
  let(:category) { create(:category, participatory_space:) }
  let(:parent_scope) { create(:scope, organization:) }
  let(:scope) { create(:subscope, parent: parent_scope) }
  let(:category_id) { category.try(:id) }
  let(:scope_id) { scope.try(:id) }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:has_address) { false }
  let(:address) { nil }
  let(:suggested_hashtags) { [] }
  let(:attachment_params) { nil }
  let(:meeting_as_author) { false }
  let(:params) do
    {
      title:,
      body:,
      terms_agreed: true,
      author:,
      category_id:,
      area_scope_id: scope_id,
      address:,
      has_address:,
      meeting_as_author:,
      attachment: attachment_params,
      suggested_hashtags:
    }
  end

  let(:form) do
    described_class.from_params(params).with_context(
      current_component: component,
      current_organization: component.organization,
      current_participatory_space: participatory_space
    )
  end

  context "when everything is OK" do
    it { is_expected.to be_valid }
  end

  context "when there's no title" do
    let(:title) { nil }

    it { is_expected.to be_invalid }

    it "only adds errors to this field" do
      subject.valid?
      if options[:i18n]
        expect(subject.errors.attribute_names).to eq [:title_en]
      else
        expect(subject.errors.attribute_names).to eq [:title]
      end
    end
  end

  context "when the title is too long" do
    let(:title) do
      if options[:i18n] == false
        "A" * 200
      else
        { en: "A" * 200 }
      end
    end

    it { is_expected.to be_invalid }
  end

  context "when the title is the minimum length" do
    let(:title) do
      if options[:i18n] == false
        "Length is right"
      else
        { en: "Length is right" }
      end
    end

    it { is_expected.to be_valid }
  end

  unless options[:skip_etiquette_validation]
    context "when the body is not etiquette-compliant" do
      let(:body) do
        if options[:i18n] == false
          "A"
        else
          { en: "A" }
        end
      end

      it { is_expected.to be_invalid }
    end
  end

  context "when there's no body" do
    let(:body) { nil }

    it { is_expected.to be_invalid }
  end

  context "when no category_id" do
    let(:category_id) { nil }

    it { is_expected.to be_valid }
  end

  context "when no scope_id" do
    let(:scope_id) { nil }

    it { is_expected.to be_valid }
  end

  context "with invalid category_id" do
    let(:category_id) { 987 }

    it { is_expected.to be_invalid }
  end

  context "when geocoding is enabled" do
    let(:component) { create(:idea_component, :with_geocoding_enabled, participatory_space:) }

    context "when the has address checkbox is checked" do
      let(:has_address) { true }

      context "when the address is not present" do
        it "does not store the coordinates" do
          expect(subject).to be_valid
          expect(subject.address).to be_nil
          expect(subject.latitude).to be_nil
          expect(subject.longitude).to be_nil
        end
      end
    end

    context "when latitude and longitude are manually set" do
      context "when the has address checkbox is unchecked" do
        let(:has_address) { false }

        it "is valid" do
          expect(subject).to be_valid
          expect(subject.latitude).to be_nil
          expect(subject.longitude).to be_nil
        end
      end

      context "when the idea is unchanged" do
        let(:previous_idea) { create(:idea, address:) }
        let(:title) do
          if options[:skip_etiquette_validation]
            previous_idea.title
          else
            translated(previous_idea.title)
          end
        end
        let(:body) do
          if options[:skip_etiquette_validation]
            previous_idea.body
          else
            translated(previous_idea.body)
          end
        end
        let(:params) do
          {
            id: previous_idea.id,
            title:,
            body:,
            terms_agreed: true,
            author: previous_idea.authors.first,
            category_id: previous_idea.try(:category_id),
            area_scope_id: previous_idea.try(:area_scope_id),
            has_address:,
            address:,
            attachment: previous_idea.try(:attachment_params),
            latitude:,
            longitude:
          }
        end

        before do
          previous_idea.update(area_scope: scope)
        end

        it "is valid" do
          expect(subject).to be_valid
          expect(subject.latitude).to eq(latitude)
          expect(subject.longitude).to eq(longitude)
        end
      end
    end
  end

  describe "category" do
    subject { form.category }

    context "when the category exists" do
      it { is_expected.to be_a(Decidim::Category) }
    end

    context "when the category does not exist" do
      let(:category_id) { 7654 }

      it { is_expected.to be_nil }
    end

    context "when the category is from another process" do
      let(:category_id) { create(:category).id }

      it { is_expected.to be_nil }
    end
  end

  it "properly maps category id from model" do
    idea = create(:idea, component:, category:)

    expect(described_class.from_model(idea).category_id).to eq(category_id)
  end

  if options && options[:user_group_check]
    it "properly maps user group id from model" do
      idea = create(:idea, component:, users: [author], user_groups: [user_group])

      expect(described_class.from_model(idea).user_group_id).to eq(user_group_id)
    end
  end

  context "when the attachment is present" do
    let(:attachment_params) do
      {
        title: "My attachment",
        file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
      }
    end

    it { is_expected.to be_valid }
  end

  describe "#extra_hashtags" do
    subject { form.extra_hashtags }

    let(:component) do
      create(
        :idea_component,
        :with_extra_hashtags,
        participatory_space:,
        suggested_hashtags: component_suggested_hashtags,
        automatic_hashtags: component_automatic_hashtags
      )
    end
    let(:component_automatic_hashtags) { "" }
    let(:component_suggested_hashtags) { "" }

    it { is_expected.to eq([]) }

    context "when there are auto hashtags" do
      let(:component_automatic_hashtags) { "HashtagAuto1 HashtagAuto2" }

      it { is_expected.to eq(%w(HashtagAuto1 HashtagAuto2)) }
    end

    context "when there are some suggested hashtags checked" do
      let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2 HashtagSuggested3" }
      let(:suggested_hashtags) { %w(HashtagSuggested1 HashtagSuggested2) }

      it { is_expected.to eq(%w(HashtagSuggested1 HashtagSuggested2)) }
    end

    context "when there are invalid suggested hashtags checked" do
      let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2" }
      let(:suggested_hashtags) { %w(HashtagSuggested1 HashtagSuggested3) }

      it { is_expected.to eq(%w(HashtagSuggested1)) }
    end

    context "when there are both suggested and auto hashtags" do
      let(:component_automatic_hashtags) { "HashtagAuto1 HashtagAuto2" }
      let(:component_suggested_hashtags) { "HashtagSuggested1 HashtagSuggested2" }
      let(:suggested_hashtags) { %w(HashtagSuggested2) }

      it { is_expected.to eq(%w(HashtagAuto1 HashtagAuto2 HashtagSuggested2)) }
    end
  end
end

shared_examples "a idea form with meeting as author" do |options|
  subject { form }

  let(:organization) { create(:organization, tos_version: Time.current, available_locales: [:en]) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:idea_component, participatory_space:) }
  let(:title) { { en: "More sidewalks and less roads!" } }
  let(:body) { { en: "Everything would be better" } }
  let(:created_in_meeting) { true }
  let(:meeting_component) { create(:meeting_component, participatory_space:) }
  let(:author) { create(:meeting, component: meeting_component) }
  let!(:meeting_as_author) { author }

  let(:params) do
    {
      title:,
      body:,
      created_in_meeting:,
      author: meeting_as_author,
      meeting_id: author.id
    }
  end

  let(:form) do
    described_class.from_params(params).with_context(
      current_component: component,
      current_organization: component.organization,
      current_participatory_space: participatory_space
    )
  end

  context "when everything is OK" do
    it { is_expected.to be_valid }
  end

  context "when there's no title" do
    let(:title) { nil }

    it { is_expected.to be_invalid }
  end

  context "when the title is too long" do
    let(:title) do
      if options[:i18n] == false
        "A" * 200
      else
        { en: "A" * 200 }
      end
    end

    it { is_expected.to be_invalid }
  end

  unless options[:skip_etiquette_validation]
    context "when the body is not etiquette-compliant" do
      let(:body) do
        if options[:i18n] == false
          "A"
        else
          { en: "A" }
        end
      end

      it { is_expected.to be_invalid }
    end
  end

  context "when there's no body" do
    let(:body) { nil }

    it { is_expected.to be_invalid }
  end

  context "when ideas comes from a meeting" do
    it "validates the meeting as author" do
      expect(subject).to be_valid
      expect(subject.author).to eq(author)
    end
  end
end
