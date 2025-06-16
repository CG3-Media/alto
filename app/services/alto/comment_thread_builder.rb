module Alto
  # Service object to handle comment threading and navigation logic
  class CommentThreadBuilder
    def initialize(ticket, comment = nil)
      @ticket = ticket
      @comment = comment
    end

    # Builds thread structure for a root comment
    def build_thread_for_comment(root_comment)
      all_comments = @ticket.comments.includes(:parent, :replies, :upvotes).order(:created_at)

      {
        comment: root_comment,
        replies: Comment.build_reply_tree(root_comment, all_comments)
      }
    end

    # Returns redirect path after creating a comment
    def redirect_path_for_reply(comment, board, ticket)
      if comment.is_reply?
        root_comment = comment.thread_root
        [board, ticket, root_comment]
      else
        [board, ticket, { anchor: "comment-#{comment.id}" }]
      end
    end

    # Returns redirect path when comment creation fails
    def redirect_path_for_failed_reply(comment_params, ticket, board)
      if comment_params[:parent_id].present?
        parent_comment = ticket.comments.find(comment_params[:parent_id])
        root_comment = parent_comment.thread_root
        [board, ticket, root_comment]
      else
        nil # Will render show template
      end
    end

    # Returns redirect path after deleting a comment
    def redirect_path_for_delete(comment, board, ticket, referrer)
      root_comment = comment.thread_root

      if in_thread_view?(referrer)
        if comment.id == root_comment.id
          [board, ticket]
        else
          [board, ticket, root_comment]
        end
      else
        [board, ticket]
      end
    end

    private

    attr_reader :ticket, :comment

    def in_thread_view?(referrer)
      referrer&.include?("/comments/") || false
    end
  end
end
