# frozen_string_literal: true

module Decidim
  module Ideas
    module AttachedIdeasHelper
      include Decidim::ApplicationHelper
      include ActionView::Helpers::FormTagHelper

      def search_ideas
        respond_to do |format|
          format.html do
            if params[:layout] == "inline"
              render partial: "decidim/ideas/attached_ideas/ideas_inline", layout: false
            else
              render partial: "decidim/ideas/attached_ideas/ideas", layout: false
            end
          end
          format.json do
            query = Decidim
                    .find_resource_manifest(:ideas)
                    .try(:resource_scope, current_component)
                    &.order(title: :asc)
                    &.where("state IS NULL OR state != ?", "rejected")
                    &.where&.not(published_at: nil)

            # In case the search term starts with a hash character and contains
            # only numbers, the user wants to search with the ID.
            query = if params[:term] =~ /^#[0-9]+$/
                      idterm = params[:term].sub(/#/, "")
                      query&.where(
                        "decidim_ideas_ideas.id::text like ?",
                        "%#{idterm}%"
                      )
                    else
                      query&.where("title ilike ?", "%#{params[:term]}%")
                    end

            ideas_list = query.all.collect do |p|
              ["#{present(p).title} (##{p.id})", p.id]
            end

            render json: ideas_list
          end
        end
      end
    end
  end
end
