module Alto
  module ApplicationHelper
    def status_badge(status)
      color_class = case status
      when "open" then "bg-green-100 text-green-800"
      when "planned" then "bg-blue-100 text-blue-800"
      when "in_progress" then "bg-yellow-100 text-yellow-800"
      when "complete" then "bg-gray-100 text-gray-800"
      else "bg-gray-100 text-gray-800"
      end

      content_tag :span, status.humanize,
                  class: "px-2 py-1 text-xs font-medium rounded-full #{color_class}"
    end

    # Unified button helper for consistent styling
    def render_button(text, options = {})
      render "shared/button",
        text: text,
        button_type: options[:button_type] || :primary,
        url: options[:url],
        method: options[:method],
        size: options[:size] || "medium",
        type: options[:type] || "button",
        disabled: options[:disabled] || false,
        additional_classes: options[:class] || "",
        html_options: options[:html_options] || {}
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

      css_classes += " transition-colors duration-200 cursor-pointer"

      # Use the toggle path for unified upvote handling
      toggle_path = upvote_toggle_path_for(upvotable)

      link_to toggle_path,
              class: css_classes,
              method: :delete,
              data: {
                upvote_button: true,
                upvoted: upvoted,
                upvotable_id: upvotable.id,
                upvotable_type: upvotable.class.name
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
      text_size = size == :large ? "text-lg" : "text-sm"

      content_tag :span, count, class: "#{text_size} font-medium"
    end

    def upvote_svg(size: :small)
      svg_size = size == :large ? "w-6 h-6" : "w-4 h-4"

      content_tag :svg, class: svg_size, fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "",
                    "fill-rule": "evenodd",
                    d: "M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z",
                    "clip-rule": "evenodd"
      end
    end

    def comment_count_text(count)
      pluralize(count, "comment")
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
      ::Alto.config.user_display_name.call(user_id)
    end

    def user_profile_avatar_url(user_id)
      ::Alto.config.user_profile_avatar_url.call(user_id)
    end

    def has_user_avatar?(user_id)
      user_profile_avatar_url(user_id).present?
    end

    def app_name
      ::Alto.config.app_name
    end

    def count_nested_replies(replies)
      replies.sum { |r| 1 + count_nested_replies(r[:replies]) }
    end

    # Current board helper method
    def current_board
      @current_board ||= begin
        if session[:current_board_slug].present?
          ::Alto::Board.find_by(slug: session[:current_board_slug]) || default_board || ::Alto::Board.first
        else
          default_board || ::Alto::Board.first
        end
      end
    end

    # Default board helper method
    def default_board
      @default_board ||= ::Alto::Board.find_by(slug: "feedback")
    end

    # Board item label helpers
    def current_board_item_name
      current_board&.item_name || "ticket"
    end

    def board_item_name(board)
      board&.item_name || "ticket"
    end

    # Custom fields helpers
    def ticket_has_custom_field_values?(ticket, board)
      board.fields.any? && visible_custom_fields(ticket, board).any?
    end

    def visible_custom_fields(ticket, board)
      board.fields.ordered.select { |field| ticket.field_value(field).present? }
    end

    def format_custom_field_value(field, value)
      return "" if value.blank?

      case field.field_type
      when "multiselect"
        format_multiselect_value(value)
      when "date"
        format_date_value(value)
      else
        value.to_s
      end
    end

    private

    def format_multiselect_value(value)
      return "" unless value.is_a?(String)

      value.split(",").map do |v|
        content_tag :span, v.strip,
                   class: "inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full mr-1"
      end.join.html_safe
    end

    def format_date_value(value)
      Date.parse(value.to_s).strftime("%B %d, %Y")
    rescue
      value.to_s
    end

    def upvote_path_for(upvotable)
      case upvotable
      when ::Alto::Ticket
        # For tickets, we need the board context
        board = upvotable.board
        alto.board_ticket_upvotes_path(board, upvotable)
      when ::Alto::Comment
        # For comments, we can still use the comment-specific route
        alto.comment_upvotes_path(upvotable)
      end
    end

    def upvote_toggle_path_for(upvotable)
      case upvotable
      when ::Alto::Ticket
        # For tickets, use the toggle action within board context
        board = upvotable.board
        alto.toggle_board_ticket_upvotes_path(board, upvotable)
      when ::Alto::Comment
        # For comments, use the toggle action
        alto.toggle_comment_upvotes_path(upvotable)
      end
    end
  end
end
