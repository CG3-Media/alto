module Alto
  module TicketsHelper
    # Generate consistent filter URLs with preserved parameters
    def filter_url_params(overrides = {})
      {
        search: params[:search],
        sort: params[:sort],
        view: params[:view],
        status: params[:status],
        tag: params[:tag]
      }.merge(overrides).compact
    end

    # Generate filter URL for board tickets
    def filter_url(board, overrides = {})
      alto.board_tickets_path(board, filter_url_params(overrides))
    end

    # Generate CSS classes for filter buttons
    def filter_button_classes(active:, type: :rounded)
      base_classes = case type
      when :rounded
        "px-3 py-1 text-sm rounded-full border"
      when :toggle
        "px-3 py-1 text-sm rounded-md transition-colors"
      when :sort
        "px-3 py-2 text-sm rounded-md"
      end

      active_classes = case type
      when :rounded
        "bg-gray-900 text-white"
      when :toggle
        "bg-white text-gray-900 shadow-sm"
      when :sort
        "bg-blue-100 text-blue-700"
      end

      inactive_classes = case type
      when :rounded, :toggle
        "bg-white text-gray-700 hover:bg-gray-50"
      when :sort
        "text-gray-600 hover:text-gray-900"
      end

      "#{base_classes} #{active ? active_classes : inactive_classes}"
    end

    # Check if view toggle should be shown
    def show_view_toggle?
      @show_toggle && @board.has_status_tracking? && params[:status].blank?
    end

    # Check if status filters should be visible
    def show_status_filters?
      @view_type == 'list'
    end
  end
end
