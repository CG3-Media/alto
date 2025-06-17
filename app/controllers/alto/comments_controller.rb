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
    ActiveRecord::Base.transaction do
      if process_comment
        redirect_to comment_redirect_path, notice: comment_success_message
      else
        handle_comment_creation_failure
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to [@board, @ticket], alert: "Failed to save: #{e.message}"
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
      comment_params_without_status
    end

    def comment_params_without_status
      permitted_params = [:content, :parent_id]

      # Allow image uploads if enabled
      if Alto.configuration.image_uploads_enabled
        permitted_params << :images  # Single file (multiple: false)
        permitted_params << { images: [] }  # Array format (if multiple: true)
        permitted_params << :remove_images  # Allow image removal
      end

      params.require(:comment).permit(*permitted_params)
    end

      def process_comment
    @comment = build_comment
    return false unless @comment.save

    update_ticket_status_if_requested
    true
  end

    def build_comment
      comment = @ticket.comments.build(comment_params_without_status)
      comment.user_id = current_user.id
      comment
    end

    def update_ticket_status_if_requested
      return unless should_update_status?

      @ticket.update!(status_slug: status_slug_param)
    end

    def should_update_status?
      can_access_admin? && status_slug_param.present? && @board.has_status_tracking?
    end

    def status_slug_param
      @status_slug_param ||= params.dig(:comment, :status_slug)
    end

    def comment_redirect_path
      thread_builder.redirect_path_for_reply(@comment, @board, @ticket)
    end

    def comment_success_message
      base_message = @comment.is_reply? ? "Reply was successfully added." : "Comment was successfully added."
      return base_message unless should_update_status?

      "#{base_message} Status updated to '#{@ticket.status_name}'."
    end

    def handle_comment_creation_failure
      redirect_path = thread_builder.redirect_path_for_failed_reply(comment_params, @ticket, @board)

      if redirect_path
        error_message = "Reply failed: #{@comment.errors.full_messages.join(', ')}"
        redirect_to alto.url_for(redirect_path), alert: error_message
      else
        @threaded_comments = Comment.threaded_for_ticket(@ticket)
        render "alto/tickets/show"
      end
    end

    def thread_builder
      @thread_builder ||= CommentThreadBuilder.new(@ticket)
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
