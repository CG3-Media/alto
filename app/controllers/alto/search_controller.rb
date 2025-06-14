module Alto
  class SearchController < ::Alto::ApplicationController
    def index
      # Global search across all boards
      @tickets = ::Alto::Ticket.active.includes(:board, :upvotes, :comments)

      # Filter by viewable statuses for non-admin users
      @tickets = @tickets.with_viewable_statuses(is_admin: can_access_admin?)

      # Filter by accessible boards
      @tickets = @tickets.joins(:board).where(boards: { is_admin_only: false }) unless can_access_admin?

      # Apply search filter
      @tickets = @tickets.search(params[:search]) if params[:search].present?

      # Apply status filter
      @tickets = @tickets.by_status(params[:status]) if params[:status].present?

      # Apply sorting
      @tickets = case params[:sort]
      when "popular"
                   @tickets.popular
      else
                   @tickets.recent
      end

      # Apply pagination with configurable per-page limit
      @tickets = @tickets.page(params[:page]).per(search_per_page)

      # Group tickets by board for display (from paginated results)
      @tickets_by_board = @tickets.group_by(&:board)

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
