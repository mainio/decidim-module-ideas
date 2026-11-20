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
  let(:taxonomy_filter) { create(:idea_taxonomy_filter, organization:) }
  let(:taxonomy) { taxonomy_filter.root_taxonomy.children.first }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:has_address) { false }
  let(:address) { nil }

  let(:attachment_params) { nil }
  let(:meeting_as_author) { false }
  let(:params) do
    {
      title:,
      body:,
      terms_agreed: true,
      author:,
      address:,
      has_address:,
      meeting_as_author:,
      attachment: attachment_params
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
        let(:previous_idea) { create(:idea, component:, category: false, area_scope: false) }
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
            has_address:,
            address:,
            attachment: previous_idea.try(:attachment_params),
            latitude:,
            longitude:
          }
        end

        it "is valid" do
          expect(subject).to be_valid
          expect(subject.latitude).to eq(latitude)
          expect(subject.longitude).to eq(longitude)
        end
      end
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
