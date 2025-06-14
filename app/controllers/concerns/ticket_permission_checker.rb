module TicketPermissionChecker
  extend ActiveSupport::Concern

  included do
    helper_method :can_assign_tags?
  end

  private

  def check_submit_permission
    unless can_submit_tickets?
      redirect_to [@board, :tickets], alert: "You do not have permission to submit tickets"
    end
  end

  def check_edit_permission(ticket)
    unless ticket.editable_by?(current_user, can_edit_any_ticket: can_edit_tickets?)
      redirect_to [@board, ticket]
      return false
    end
    true
  end

  def ensure_not_archived
    if @ticket.archived?
      redirect_to [@board, @ticket], alert: "Archived tickets cannot be modified."
      return false
    end
    true
  end

  def can_assign_tags?
    @board.tags_assignable_by?(current_user, can_edit_any_ticket: can_edit_tickets?)
  end
end
