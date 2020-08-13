# frozen_string_literal: true

module Decidim
  module Ideas
    # A service to encapsualte all the logic when searching and filtering
    # ideas in a participatory process.
    class IdeaSearch < ResourceSearch
      # Public: Initializes the service.
      # component     - A Decidim::Component to get the ideas from.
      # page        - The page number to paginate the results.
      # per_page    - The number of ideas to return per page.
      def initialize(options = {})
        @component = options[:component]
        @current_user = options[:current_user]

        base = options[:state]&.member?("withdrawn") ? Idea.withdrawn : Idea.except_withdrawn
        super(base, options)
      end

      # Handle the search_text filter
      def search_search_text
        query
          .where("decidim_ideas_ideas.title ILIKE ?", "%#{search_text}%")
          .or(query.where("decidim_ideas_ideas.body ILIKE ?", "%#{search_text}%"))
      end

      # Handle the origin filter
      def search_origin
        citizens = origin.member?("citizens") ? query.citizens_origin : nil
        user_group = origin.member?("user_group") ? query.user_group_origin : nil

        query
          .where(id: citizens)
          .or(query.where(id: user_group))
      end

      # Handle the activity filter
      def search_activity
        case activity
        when "voted"
          query
            .includes(:votes)
            .where(decidim_ideas_idea_votes: { decidim_author_id: @current_user })
        when "my_ideas"
          query
            .where.not(coauthorships_count: 0)
            .joins(:coauthorships)
            .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
            .where(decidim_coauthorships: { decidim_author_id: @current_user })
        else # Assume 'all'
          query
        end
      end

      # Handle the state filter
      def search_state
        return query if state.member? "withdrawn"

        accepted = state.member?("accepted") ? query.accepted : nil
        rejected = state.member?("rejected") ? query.rejected : nil
        evaluating = state.member?("evaluating") ? query.evaluating : nil
        not_answered = state.member?("not_answered") ? query.state_not_published : nil

        query
          .where(id: accepted)
          .or(query.where(id: rejected))
          .or(query.where(id: evaluating))
          .or(query.where(id: not_answered))
      end

      # Handle the amendment type filter
      def search_type
        case type
        when "ideas"
          query.only_amendables
        when "amendments"
          query.only_visible_emendations_for(@current_user, @component)
        else # Assume 'all'
          query.amendables_and_visible_emendations_for(@current_user, @component)
        end
      end

      def search_category_id
        super
      end

    # Handles the area_scope_id filter. When we want to show only those that do
    # not have a area_scope_id set, we cannot pass an empty String or nil
    # because Searchlight will automatically filter out these params, so the
    # method will not be used. Instead, we need to pass a fake ID and then
    # convert it inside. In this case, in order to select those elements that do
    # not have a area_scope_id set we use `"global"` as parameter, and in the
    # method we do the needed changes to search properly.
    def search_area_scope_id
      return query if area_scope_ids.empty? || area_scope_ids.include?("all")

      conditions = []
      conditions.concat(["? = ANY(decidim_area_scopes.part_of)"] * area_scope_ids.count)

      join = %{
        LEFT OUTER JOIN decidim_scopes AS decidim_area_scopes
          ON decidim_area_scopes.id = decidim_ideas_ideas.area_scope_id
      }
      query.includes(:area_scope).joins(join).where(
        conditions.join(" OR "),
        *area_scope_ids.map(&:to_i)
      )
    end

      # Filters Ideas by the name of the classes they are linked to. By default,
      # returns all Ideas. When a `related_to` param is given, then it camelcases item
      # to find the real class name and checks the links for the Ideas.
      #
      # The `related_to` param is expected to be in this form:
      #
      #   "decidim/meetings/meeting"
      #
      # This can be achieved by performing `klass.name.underscore`.
      #
      # Returns only those ideas that are linked to the given class name.
      def search_related_to
        from = query
               .joins(:resource_links_from)
               .where(decidim_resource_links: { to_type: related_to.camelcase })

        to = query
             .joins(:resource_links_to)
             .where(decidim_resource_links: { from_type: related_to.camelcase })

        query.where(id: from).or(query.where(id: to))
      end

      # We overwrite the `results` method to ensure we only return unique
      # results. We can't use `#uniq` because it returns an Array and we're
      # adding scopes in the controller, and `#distinct` doesn't work here
      # because in the later scopes we're ordering by `RANDOM()` in a DB level,
      # and `SELECT DISTINCT` doesn't work with `RANDOM()` sorting, so we need
      # to perform two queries.
      #
      # The correct behaviour is backed by tests.
      def results
        Idea.where(id: super.pluck(:id))
      end

      private

      # Private: Returns an array with checked scope ids.
      def area_scope_ids
        @area_scope_ids ||= begin
          if area_scope_id.is_a?(Hash)
            area_scope_id.values
          else
            [area_scope_id].flatten
          end
        end
      end
    end
  end
end
