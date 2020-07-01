# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user destroys a draft idea.
    class DestroyIdea < Rectify::Command
      # Public: Initializes the command.
      #
      # idea     - The idea to destroy.
      # current_user - The current user.
      def initialize(idea, current_user)
        @idea = idea
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the idea is deleted.
      # - :invalid if the idea is not a draft.
      # - :invalid if the idea's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @idea.draft?
        return broadcast(:invalid) unless @idea.authored_by?(@current_user)

        @idea.destroy!

        broadcast(:ok, @idea)
      end
    end
  end
end
