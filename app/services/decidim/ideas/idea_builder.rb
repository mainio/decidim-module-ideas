# frozen_string_literal: true

require "open-uri"

module Decidim
  module Ideas
    # A factory class to ensure we always create Ideas the same way since it involves some logic.
    module IdeaBuilder
      # Public: Creates a new Idea.
      #
      # attributes        - The Hash of attributes to create the Idea with.
      # author            - An Authorable the will be the first coauthor of the Idea.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the Idea in the traceability logs.
      #
      # Returns a Idea.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Idea, action_user, visibility: "all") do
          idea = Idea.new(attributes)
          idea.add_coauthor(author, user_group: user_group_author)
          idea.save!
          idea
        end
      end

      module_function :create

      # Public: Creates a new Idea with the authors of the `original_idea`.
      #
      # attributes - The Hash of attributes to create the Idea with.
      # action_user - The User to be used as the user who is creating the idea in the traceability logs.
      # original_idea - The idea from which authors will be copied.
      #
      # Returns a Idea.
      def create_with_authors(attributes:, action_user:, original_idea:)
        Decidim.traceability.perform_action!(:create, Idea, action_user, visibility: "all") do
          idea = Idea.new(attributes)
          original_idea.coauthorships.each do |coauthorship|
            idea.add_coauthor(coauthorship.author, user_group: coauthorship.user_group)
          end
          idea.save!
          idea
        end
      end

      module_function :create_with_authors

      # Public: Creates a new Idea by copying the attributes from another one.
      #
      # original_idea     - The Idea to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Idea.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the idea in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new idea, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two ideas or not (default false).
      #
      # Returns a Idea
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_idea, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_idea.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "answer",
          "answered_at",
          "reference"
        ).merge(
          "category" => original_idea.category
        ).merge(
          extra_attributes
        )
        origin_attributes.delete("decidim_component_id") if extra_attributes.has_key?(:component) || extra_attributes.has_key?("component")

        idea = begin
          if author.nil?
            create_with_authors(
              attributes: origin_attributes,
              original_idea: original_idea,
              action_user: action_user
            )
          else
            create(
              attributes: origin_attributes,
              author: author,
              user_group_author: user_group_author,
              action_user: action_user
            )
          end
        end

        idea.link_resources(original_idea, "copied_from_component") unless skip_link
        copy_attachments(original_idea, idea)

        idea
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy

      def copy_attachments(original_idea, idea)
        original_idea.attachments.each do |attachment|
          new_attachment = Decidim::Attachment.new(attachment.attributes.slice("content_type", "description", "file", "file_size", "title", "weight"))
          new_attachment.attached_to = idea

          if File.exist?(attachment.file.file.path)
            new_attachment.file = File.open(attachment.file.file.path)
          else
            new_attachment.remote_file_url = attachment.url
          end

          new_attachment.save!
        end
      rescue Errno::ENOENT, OpenURI::HTTPError => e
        Rails.logger.warn("[ERROR] Couldn't copy attachment from idea #{original_idea.id} when copying to component due to #{e.message}")
      end

      module_function :copy_attachments
    end
  end
end
