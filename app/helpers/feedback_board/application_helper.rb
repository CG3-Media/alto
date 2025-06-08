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

      stimulus_upvote_button(upvotable, current_user, options)
    end

    def stimulus_upvote_button(upvotable, current_user, options = {})
      upvoted = upvotable.upvoted_by?(current_user)
      path = upvote_path_for(upvotable)

      css_classes = if options[:large]
        "flex flex-col items-center p-3 rounded-lg"
      else
        "flex items-center space-x-1 px-2 py-1 rounded-md"
      end

      # Add base hover classes
      css_classes += " hover:bg-blue-50 transition-colors duration-200"

      content_tag :button,
                  class: css_classes,
                  data: {
                    controller: "upvote",
                    upvote_target: "button",
                    upvote_url_value: path,
                    upvote_upvoted_value: upvoted,
                    upvote_count_value: upvotable.upvotes_count,
                    action: "click->upvote#toggle"
                  } do
        content = ""
        if options[:large]
          content += content_tag(:div, upvote_svg(size: :large), data: { upvote_target: "icon" })
          content += content_tag(:span, upvotable.upvotes_count, class: "text-lg font-bold", data: { upvote_target: "count" })
          content += content_tag(:span, "votes", class: "text-xs")
        else
          content += content_tag(:div, upvote_svg, data: { upvote_target: "icon" })
          content += content_tag(:span, upvotable.upvotes_count, class: "text-sm font-medium", data: { upvote_target: "count" })
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
      FeedbackBoard.config.user_display_name_method.call(user_id)
    end

    private

    def upvote_path_for(upvotable)
      case upvotable
      when FeedbackBoard::Ticket
        feedback_board.ticket_upvotes_path(upvotable)
      when FeedbackBoard::Comment
        feedback_board.comment_upvotes_path(upvotable)
      end
    end
  end
end
