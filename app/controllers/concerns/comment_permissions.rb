# Comment-specific permission management concern
module CommentPermissions
  extend ActiveSupport::Concern

  private

  def check_comment_permission
    unless can_comment? && @ticket.can_be_commented_on?
      redirect_to [@board, @ticket], alert: "You cannot comment on this ticket."
    end
  end

  def can_delete_comment?(comment)
    return false unless current_user

    # Users can delete their own comments, or admins can delete any comment
    comment.user_id == current_user.id || can_moderate_comments?
  end

  def can_moderate_comments?
    # This should be overridden by the host application
    # Example: current_user.admin? || current_user.can?(:moderate_feedback_comments)
    false
  end

  def ensure_not_archived
    if @ticket.archived?
      redirect_to [@board, @ticket], alert: "Archived tickets cannot be modified."
    end
  end

  def validate_parent_comment
    return unless params[:comment][:parent_id].present?

    @parent_comment = @ticket.comments.find(params[:comment][:parent_id])

    unless @parent_comment.can_be_replied_to?
      redirect_to [@board, @ticket], alert: "Cannot reply to this comment."
      nil
    end
  end
end
