module FeedbackBoard
  class CommentsController < ::FeedbackBoard::ApplicationController
    before_action :set_board
    before_action :set_ticket
    before_action :check_comment_permission, only: [:create]
    before_action :set_comment, only: [:show, :destroy]
    before_action :set_parent_comment, only: [:create], if: -> { params[:comment] && params[:comment][:parent_id].present? }

                def create
      @comment = @ticket.comments.build(comment_params)
      @comment.user_id = current_user.id

      if @comment.save
                if @comment.is_reply?
          # Redirect to the thread view of the root comment
          root_comment = @comment.thread_root
          redirect_to feedback_board.board_ticket_comment_path(@board, @ticket, root_comment),
                      notice: 'Reply was successfully added.'
        else
          redirect_to feedback_board.board_ticket_path(@board, @ticket, anchor: "comment-#{@comment.id}"),
                      notice: 'Comment was successfully added.'
        end
            else
        # Handle validation errors
        if @comment.parent_id.present?
          # This is a reply that failed validation - redirect back to thread
          root_comment = @ticket.comments.find(@comment.parent_id).thread_root
          error_message = "Reply failed: #{@comment.errors.full_messages.join(', ')}"
          redirect_to feedback_board.board_ticket_comment_path(@board, @ticket, root_comment),
                      alert: error_message
        else
          # This is a top-level comment that failed validation
          @threaded_comments = ::FeedbackBoard::Comment.threaded_for_ticket(@ticket)
          render 'feedback_board/tickets/show'
        end
      end
    end

    def show
      # Get the root comment of this thread
      @root_comment = @comment.thread_root

      # Build threaded structure for this specific comment thread
      @thread_comments = build_thread_for_comment(@root_comment)

      # Create a new comment for the reply form
      @new_comment = ::FeedbackBoard::Comment.new
    end

    def destroy
      if can_delete_comment?(@comment)
        # Check if we're in a thread view (has referrer to comment show page)
        if request.referer&.include?("/comments/")
          # Get the root comment for redirection
          root_comment = @comment.thread_root

          # If deleting the root comment, redirect to ticket
          if @comment.id == root_comment.id
            @comment.destroy
            redirect_to [@board, @ticket], notice: 'Comment thread was successfully deleted.'
          else
            @comment.destroy
            redirect_to feedback_board.board_ticket_comment_path(@board, @ticket, root_comment),
                        notice: 'Reply was successfully deleted.'
          end
        else
          @comment.destroy
          redirect_to [@board, @ticket], notice: 'Comment was successfully deleted.'
        end
      else
        redirect_to [@board, @ticket], alert: 'You do not have permission to delete this comment.'
      end
    end

    private

    def set_board
      @board = Board.find_by!(slug: params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:ticket_id])
    end

    def set_comment
      @comment = @ticket.comments.find(params[:id])
    end

                def set_parent_comment
      return unless params[:comment][:parent_id].present?

      @parent_comment = @ticket.comments.find(params[:comment][:parent_id])

      unless @parent_comment.can_be_replied_to?
        redirect_to [@board, @ticket], alert: 'Cannot reply to this comment.'
        return
      end
    end

            def build_thread_for_comment(root_comment)
      # Simple approach: get all comments and let build_reply_tree handle the filtering
      all_comments = @ticket.comments.includes(:parent, :replies, :upvotes).order(:created_at)

      # Build the threaded structure
      {
        comment: root_comment,
        replies: ::FeedbackBoard::Comment.build_reply_tree(root_comment, all_comments)
      }
    end

    def comment_params
      params.require(:comment).permit(:content, :parent_id)
    end

    def check_comment_permission
      unless can_comment? && @ticket.can_be_commented_on?
        redirect_to [@board, @ticket], alert: 'You cannot comment on this ticket.'
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
