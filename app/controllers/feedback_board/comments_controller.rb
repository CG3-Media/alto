module FeedbackBoard
  class CommentsController < ApplicationController
    before_action :set_ticket
    before_action :check_comment_permission, only: [:create]
    before_action :set_comment, only: [:destroy]

    def create
      @comment = @ticket.comments.build(comment_params)
      @comment.user_id = current_user.id

      if @comment.save
        redirect_to @ticket, notice: 'Comment was successfully added.'
      else
        @comments = @ticket.comments.includes(:upvotes).recent
        render 'feedback_board/tickets/show'
      end
    end

    def destroy
      if can_delete_comment?(@comment)
        @comment.destroy
        redirect_to @ticket, notice: 'Comment was successfully deleted.'
      else
        redirect_to @ticket, alert: 'You do not have permission to delete this comment.'
      end
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def set_comment
      @comment = @ticket.comments.find(params[:id])
    end

    def comment_params
      params.require(:comment).permit(:content)
    end

    def check_comment_permission
      unless can_comment? && @ticket.can_be_commented_on?
        redirect_to @ticket, alert: 'You cannot comment on this ticket.'
      end
    end

    def can_delete_comment?(comment)
      # Users can delete their own comments, or admins can delete any comment
      comment.user_id == current_user.id || can_moderate_comments?
    end

    def can_moderate_comments?
      # This should be overridden by the host application
      # Example: current_user.admin? || current_user.can?(:moderate_feedback_comments)
      false
    end
  end
end
