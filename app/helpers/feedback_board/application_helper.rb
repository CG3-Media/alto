module FeedbackBoard
  module ApplicationHelper
    def status_badge(status)
      color_class = case status
                    when 'open' then 'bg-green-100 text-green-800'
                    when 'planned' then 'bg-blue-100 text-blue-800'
                    when 'in_progress' then 'bg-yellow-100 text-yellow-800'
                    when 'complete' then 'bg-gray-100 text-gray-800'
                    else 'bg-gray-100 text-gray-800'
                    end

      content_tag :span, status.humanize,
                  class: "px-2 py-1 text-xs font-medium rounded-full #{color_class}"
    end

    def locked_badge
      content_tag :span, "🔒 Locked",
                  class: "px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800"
    end

    def upvote_button(upvotable, current_user, options = {})
      return disabled_upvote_button(upvotable) unless can_vote? && upvotable.can_be_voted_on?

      ajax_upvote_button(upvotable, current_user, options)
    end

    def ajax_upvote_button(upvotable, current_user, options = {})
      upvoted = upvotable.upvoted_by?(current_user)
      path = upvote_path_for(upvotable)

      css_classes = if options[:large]
        "flex flex-col items-center p-3 rounded-lg"
      else
        "flex items-center space-x-1 px-2 py-1 rounded-md"
      end

      # Add styling based on upvote state
      if upvoted
        css_classes += " bg-blue-50 text-blue-600 hover:bg-blue-100"
      else
        css_classes += " text-gray-400 hover:text-blue-600 hover:bg-blue-50"
      end

      css_classes += " transition-colors duration-200"

      link_to path,
              class: css_classes,
              method: upvoted ? :delete : :post,
              data: {
                upvote_button: true,
                method: upvoted ? 'DELETE' : 'POST'
              } do
        content = ""
        if options[:large]
          content += content_tag(:div, upvote_svg(size: :large))
          content += content_tag(:span, upvotable.upvotes_count, class: "text-lg font-bold", data: { upvote_count: true })
          content += content_tag(:span, "votes", class: "text-xs")
        else
          content += content_tag(:div, upvote_svg)
          content += content_tag(:span, upvotable.upvotes_count, class: "text-sm font-medium", data: { upvote_count: true })
        end
        content.html_safe
      end
    end

    def upvote_count_display(upvotable, size: :small)
      count = upvotable.upvotes_count
      text_size = size == :large ? 'text-lg' : 'text-sm'

      content_tag :span, count, class: "#{text_size} font-medium"
    end

    def upvote_svg(size: :small)
      svg_size = size == :large ? 'w-6 h-6' : 'w-4 h-4'

      content_tag :svg, class: svg_size, fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "",
                    "fill-rule": "evenodd",
                    d: "M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z",
                    "clip-rule": "evenodd"
      end
    end

    def comment_count_text(count)
      pluralize(count, 'comment')
    end

    def time_ago_text(timestamp)
      "#{time_ago_in_words(timestamp)} ago"
    end

    def truncate_description(description, length: 150)
      truncate(description, length: length)
    end

    def disabled_upvote_button(upvotable, options = {})
      css_classes = if options[:large]
        "flex flex-col items-center p-3 text-gray-300"
      else
        "flex items-center space-x-1 px-2 py-1 text-gray-300"
      end

      content_tag :div, class: css_classes do
        content = ""
        if options[:large]
          content += content_tag(:div, upvote_svg(size: :large))
          content += content_tag(:span, upvotable.upvotes_count, class: "text-lg font-bold")
          content += content_tag(:span, "votes", class: "text-xs")
        else
          content += upvote_svg.to_s
          content += content_tag(:span, upvotable.upvotes_count, class: "text-sm font-medium")
        end
        content.html_safe
      end
    end

    def user_display_name(user_id)
      ::FeedbackBoard.config.user_display_name_method.call(user_id)
    end

    def app_name
      ::FeedbackBoard.config.app_name
    end

    def count_nested_replies(replies)
      replies.sum { |r| 1 + count_nested_replies(r[:replies]) }
    end

    # Current board helper method
    def current_board
      @current_board ||= begin
        if session[:current_board_slug].present?
          ::FeedbackBoard::Board.find_by(slug: session[:current_board_slug]) || default_board || ::FeedbackBoard::Board.first
        else
          default_board || ::FeedbackBoard::Board.first
        end
      end
    end

    # Default board helper method
    def default_board
      @default_board ||= ::FeedbackBoard::Board.find_by(slug: 'feedback')
    end

    private

    def upvote_path_for(upvotable)
      case upvotable
      when ::FeedbackBoard::Ticket
        # For tickets, we need the board context
        board = upvotable.board
        feedback_board.board_ticket_upvotes_path(board, upvotable)
      when ::FeedbackBoard::Comment
        # For comments, we can still use the comment-specific route
        feedback_board.comment_upvotes_path(upvotable)
      end
    end
  end
end
