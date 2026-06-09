# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Ideas
    describe IdeasFormHelper do
      let(:organization) { create(:organization) }
      let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
      let(:component) { create(:idea_component, participatory_space:) }

      before do
        allow(helper).to receive(:current_component).and_return(component)
        allow(helper).to receive(:component_settings).and_return(component.settings)
        allow(helper).to receive(:user_signed_in?).and_return(true)
      end

      # ---------------------------------------------------------------------------
      # file_field
      # ---------------------------------------------------------------------------
      describe "#file_field" do
        context "when the user is signed in" do
          before { allow(helper).to receive(:user_signed_in?).and_return(true) }

          it "does not set disabled on options" do
            options = {}
            # Capture the super call; we just verify disabled is NOT set to true
            allow(helper).to receive(:file_field).and_call_original
            # We spy on the options hash before super is called
            expect(options[:disabled]).to be_nil
            helper.file_field("idea", :attachment, options)
            expect(options[:disabled]).to be_nil
          end
        end

        context "when the user is not signed in" do
          before { allow(helper).to receive(:user_signed_in?).and_return(false) }

          it "sets disabled: true on the options hash before calling super" do
            options = {}
            allow(helper).to receive(:file_field).and_wrap_original do |orig, *args|
              orig.call(*args)
            rescue StandardError
              nil
            end

            helper.file_field("idea", :attachment, options)
            expect(options[:disabled]).to be(true)
          end
        end
      end

      # ---------------------------------------------------------------------------
      # file_is_present?
      # ---------------------------------------------------------------------------
      describe "#file_is_present?" do
        let(:form) { double("form") }
        let(:file_form) { double("file_form") }
        let(:file) { double("file") }

        context "when the attribute returns nil" do
          before do
            allow(form).to receive(:object).and_return(double(attachment: nil))
          end

          it "returns false" do
            expect(helper.file_is_present?(form, :attachment)).to be(false)
          end
        end

        context "when the file form has no file" do
          before do
            allow(file_form).to receive(:file).and_return(nil)
            obj = double(attachment: file_form)
            allow(form).to receive(:object).and_return(obj)
          end

          it "returns false" do
            expect(helper.file_is_present?(form, :attachment)).to be(false)
          end
        end

        context "when the file does not respond to :attached?" do
          before do
            allow(file).to receive(:respond_to?).with(:attached?).and_return(false)
            allow(file_form).to receive(:file).and_return(file)
            obj = double(attachment: file_form)
            allow(form).to receive(:object).and_return(obj)
          end

          it "returns false" do
            expect(helper.file_is_present?(form, :attachment)).to be(false)
          end
        end

        context "when the file is not attached" do
          before do
            allow(file).to receive(:respond_to?).with(:attached?).and_return(true)
            allow(file).to receive(:attached?).and_return(false)
            allow(file).to receive(:present?).and_return(false)
            allow(file_form).to receive(:file).and_return(file)
            obj = double(attachment: file_form)
            allow(form).to receive(:object).and_return(obj)
          end

          it "returns false" do
            expect(helper.file_is_present?(form, :attachment)).to be(false)
          end
        end

        context "when the file is attached and present" do
          before do
            allow(file).to receive(:respond_to?).with(:attached?).and_return(true)
            allow(file).to receive(:attached?).and_return(true)
            allow(file).to receive(:present?).and_return(true)
            allow(file_form).to receive(:file).and_return(file)
            obj = double(attachment: file_form)
            allow(form).to receive(:object).and_return(obj)
          end

          it "returns true" do
            expect(helper.file_is_present?(form, :attachment)).to be(true)
          end
        end
      end
    end
  end
end
