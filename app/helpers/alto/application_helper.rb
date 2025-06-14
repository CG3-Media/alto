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
      # Hide upvote button completely if board doesn't allow voting
      return nil unless board_allows_voting?(upvotable)

      # Show disabled button if user can't vote or item can't be voted on
      return disabled_upvote_button(upvotable) unless can_vote? && upvotable.can_be_voted_on?

      ajax_upvote_button(upvotable, current_user, options)
    end

    def ajax_upvote_button(upvotable, current_user, options = {})
      upvoted = upvotable.upvoted_by?(current_user)
      size = options[:size] || :default

      # Define size-specific styling
      case size
      when :large
        base_classes = "flex flex-col items-center justify-center p-4 rounded-xl min-w-[4rem] min-h-[5rem]"
        arrow_size = :large
        count_classes = "text-2xl font-bold mt-2 leading-none"
        label_classes = "text-xs mt-1 leading-none"
      when :small
        base_classes = "flex items-center justify-center gap-1 px-2 py-1 rounded-md border"
        arrow_size = :small
        count_classes = "text-sm font-bold leading-none"
        label_classes = "text-xs opacity-75 leading-none"
      when :compact
        base_classes = "flex flex-col items-center justify-center p-2 rounded-lg min-w-[3rem] min-h-[3.5rem] border"
        arrow_size = :medium
        count_classes = "text-lg font-bold mt-1.5 leading-none"
        label_classes = "text-xs opacity-75 leading-none"
      else
        base_classes = "flex flex-col items-center justify-center p-3 rounded-lg min-w-[3.5rem] min-h-[4.5rem] border"
        arrow_size = :medium
        count_classes = "text-xl font-bold mt-2 leading-none"
        label_classes = "text-xs leading-none"
      end

      # Add styling based on upvote state
      if upvoted
        state_classes = " bg-blue-600 text-white border-blue-600 hover:bg-blue-700 shadow-lg transform scale-105"
      else
        state_classes = " bg-white text-gray-600 border-gray-200 hover:border-blue-400 hover:bg-blue-50 hover:text-blue-600 hover:shadow-md"
      end

      css_classes = base_classes + state_classes + " transition-all duration-200 cursor-pointer group"

      # Use the toggle path for unified upvote handling
      toggle_path = upvote_toggle_path_for(upvotable)

      link_to toggle_path,
              class: css_classes,
              method: :delete,
              data: {
                upvote_button: true,
                upvoted: upvoted,
                upvotable_id: upvotable.id,
                upvotable_type: upvotable.class.name,
                remote: false
              } do
        content = ""
        content += content_tag(:div, upvote_svg(size: arrow_size), class: "group-hover:scale-110 transition-transform duration-200")
        content += content_tag(:span, upvotable.upvotes_count, class: count_classes, data: { upvote_count: true })
        if size == :large
          content += content_tag(:span, "votes", class: label_classes)
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
      svg_size = case size
                 when :large then "w-8 h-8"
                 when :medium then "w-5 h-5"
                 else "w-4 h-4"
                 end

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
      size = options[:size] || :default

      # Define size-specific styling to match active buttons
      case size
      when :large
        base_classes = "flex flex-col items-center justify-center p-4 rounded-xl min-w-[4rem] min-h-[5rem]"
        arrow_size = :large
        count_classes = "text-2xl font-bold mt-2 leading-none"
        label_classes = "text-xs mt-1 leading-none"
      when :small
        base_classes = "flex items-center justify-center gap-1 px-2 py-1 rounded-md border"
        arrow_size = :small
        count_classes = "text-sm font-bold leading-none"
        label_classes = "text-xs opacity-75 leading-none"
      when :compact
        base_classes = "flex flex-col items-center justify-center p-2 rounded-lg min-w-[3rem] min-h-[3.5rem] border"
        arrow_size = :medium
        count_classes = "text-lg font-bold mt-1.5 leading-none"
        label_classes = "text-xs opacity-75 leading-none"
      else
        base_classes = "flex flex-col items-center justify-center p-3 rounded-lg min-w-[3.5rem] min-h-[4.5rem] border"
        arrow_size = :medium
        count_classes = "text-xl font-bold mt-2 leading-none"
        label_classes = "text-xs leading-none"
      end

      css_classes = base_classes + " bg-gray-100 text-gray-400 border-gray-200 cursor-not-allowed opacity-60"

      content_tag :div, class: css_classes do
        content = ""
        content += content_tag(:div, upvote_svg(size: arrow_size))
        content += content_tag(:span, upvotable.upvotes_count, class: count_classes)
        if size == :large
          content += content_tag(:span, "votes", class: label_classes)
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

    def board_allows_voting?(upvotable)
      case upvotable
      when ::Alto::Ticket
        # For tickets, check the board's voting setting
        upvotable.board&.allow_voting? != false
      when ::Alto::Comment
        # Comments are always upvotable regardless of board setting
        true
      else
        # Default to true for other types
        true
      end
    end
  end
end
