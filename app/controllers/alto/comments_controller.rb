module Alto
  class CommentsController < ::Alto::ApplicationController
    include BoardScoped
    include CommentPermissions

    before_action :set_board
    before_action :set_ticket
    before_action :check_comment_permission, only: [:create]
    before_action :set_comment, only: [:show, :destroy]
    before_action :validate_parent_comment, only: [:create], if: -> { params[:comment]&.dig(:parent_id).present? }
    before_action :ensure_not_archived, only: [:create, :destroy]

    def create
      @comment = @ticket.comments.build(comment_params)
      @comment.user_id = current_user.id
      thread_builder = CommentThreadBuilder.new(@ticket)

      if @comment.save
        redirect_path = thread_builder.redirect_path_for_reply(@comment, @board, @ticket)
        redirect_to alto.url_for(redirect_path), notice: success_message_for(@comment)
      else
        handle_failed_comment_creation(thread_builder)
      end
    end

    def show
      @root_comment = @comment.thread_root
      thread_builder = CommentThreadBuilder.new(@ticket)
      @thread_comments = thread_builder.build_thread_for_comment(@root_comment)
      @new_comment = Comment.new
    end

    def destroy
      if can_delete_comment?(@comment)
        thread_builder = CommentThreadBuilder.new(@ticket)
        redirect_path = thread_builder.redirect_path_for_delete(@comment, @board, @ticket, request.referer)

        @comment.destroy
        redirect_to alto.url_for(redirect_path), notice: delete_success_message(@comment)
      else
        redirect_to [@board, @ticket], alert: "You do not have permission to delete this comment."
      end
    end

    private

    def set_ticket
      @ticket = @board.tickets.find(params[:ticket_id])
    end

    def set_comment
      @comment = @ticket.comments.find(params[:id])
    end

    def comment_params
      permitted_params = [:content, :parent_id]

      # Allow image uploads if enabled
      if Alto.configuration.image_uploads_enabled
        permitted_params << :images  # Single file (multiple: false)
        permitted_params << { images: [] }  # Array format (if multiple: true)
        permitted_params << :remove_images  # Allow image removal
      end

      params.require(:comment).permit(*permitted_params)
    end

    def handle_failed_comment_creation(thread_builder)
      redirect_path = thread_builder.redirect_path_for_failed_reply(comment_params, @ticket, @board)

      if redirect_path
        error_message = "Reply failed: #{@comment.errors.full_messages.join(', ')}"
        redirect_to alto.url_for(redirect_path), alert: error_message
      else
        @threaded_comments = Comment.threaded_for_ticket(@ticket)
        render "alto/tickets/show"
      end
    end

    def success_message_for(comment)
      comment.is_reply? ? "Reply was successfully added." : "Comment was successfully added."
    end

    def delete_success_message(comment)
      root_comment = comment.thread_root
      if comment.id == root_comment.id
        "Comment thread was successfully deleted."
      else
        "Reply was successfully deleted."
      end
    end
  end
end
