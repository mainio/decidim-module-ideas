# frozen_string_literal: true

module Decidim
  module Ideas
    # A command with all the business logic when a user withdraws a new idea.
    class WithdrawIdea < Rectify::Command
      # Public: Initializes the command.
      #
      # idea     - The idea to withdraw.
      # current_user - The current user.
      def initialize(idea, current_user)
        @idea = idea
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the idea.
      # - :has_supports if the idea already has supports or does not belong to current user.
      #
      # Returns nothing.
      def call
        transaction do
          change_idea_state_to_withdrawn
          reject_emendations_if_any
        end

        broadcast(:ok, @idea)
      end

      private

      def change_idea_state_to_withdrawn
        @idea.update state: "withdrawn"
      end

      def reject_emendations_if_any
        return if @idea.emendations.empty?

        @idea.emendations.each do |emendation|
          @form = form(Decidim::Amendable::RejectForm).from_params(id: emendation.amendment.id)
          result = Decidim::Amendable::Reject.call(@form)
          return result[:ok] if result[:ok]
        end
      end
    end
  end
end
