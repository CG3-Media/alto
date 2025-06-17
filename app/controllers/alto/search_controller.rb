module Alto
  class SearchController < ::Alto::ApplicationController
    def index
      # Simple global search - start with basics
      @tickets = ::Alto::Ticket.active.includes(:board)

      # Apply search filter
      if params[:search].present?
        @tickets = @tickets.search(params[:search])
        # Get 26 results to check if there are more than 25
        results = @tickets.limit(26).to_a
        @has_more_results = results.length > 25
        @tickets = results.first(25)  # Only show first 25
      else
        # Just show recent tickets when no search
        @tickets = @tickets.recent.limit(25).to_a
        @has_more_results = false
      end

      @search_query = params[:search]
      @is_global_search = true
    end

    private

    def search_per_page
      # Allow per-page customization via params, with reasonable limits
      per_page = params[:per_page].to_i
      return 25 if per_page <= 0  # Default
      return 100 if per_page > 100  # Maximum
      per_page
    end
  end
end
