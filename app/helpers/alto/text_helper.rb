module Alto
  module TextHelper
    def comment_count_text(count)
      pluralize(count, "comment")
    end

    def time_ago_text(timestamp)
      "#{time_ago_in_words(timestamp)} ago"
    end

    def truncate_description(description, length: 150)
      truncate(description, length: length)
    end

    def count_nested_replies(replies)
      replies.sum { |r| 1 + count_nested_replies(r[:replies]) }
    end

    private

    def format_date_value(value)
      Date.parse(value.to_s).strftime("%B %d, %Y")
    rescue
      value.to_s
    end
  end
end
