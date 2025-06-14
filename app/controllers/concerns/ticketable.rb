# Shared functionality for controllers that deal with ticket filtering and display
module Ticketable
  extend ActiveSupport::Concern

  included do
    helper_method :current_view_type, :show_view_toggle?
  end

  private

  def apply_ticket_filters(tickets)
    tickets = filter_by_status(tickets)
    tickets = filter_by_viewable_statuses(tickets)
    tickets = filter_by_tag(tickets)
    tickets = apply_search(tickets)
    apply_sorting(tickets)
  end

  def filter_by_status(tickets)
    return tickets unless params[:status].present?
    tickets.by_status(params[:status])
  end

  def filter_by_viewable_statuses(tickets)
    tickets.with_viewable_statuses(is_admin: can_access_admin?)
  end

  def filter_by_tag(tickets)
    return tickets unless params[:tag].present?
    tickets.tagged_with(params[:tag])
  end

  def apply_search(tickets)
    return tickets unless params[:search].present?
    tickets.search(params[:search])
  end

  def apply_sorting(tickets)
    case params[:sort]
    when "popular"
      tickets.popular
    else
      tickets.recent
    end
  end

  def determine_view_type(board)
    Alto::ViewTypeResolver.new(board, params[:view], session).resolve
  end

  def current_view_type
    @view_type
  end

  def show_view_toggle?
    @show_toggle
  end
end
