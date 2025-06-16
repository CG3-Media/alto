require 'test_helper'

class Alto::TextHelperTest < ActionView::TestCase
  include Alto::TextHelper

  test "comment_count_text returns singular for 1 comment" do
    result = comment_count_text(1)
    assert_equal "1 comment", result
  end

  test "comment_count_text returns plural for 0 comments" do
    result = comment_count_text(0)
    assert_equal "0 comments", result
  end

  test "comment_count_text returns plural for multiple comments" do
    result = comment_count_text(5)
    assert_equal "5 comments", result
  end

  test "time_ago_text formats recent time correctly" do
    timestamp = 2.hours.ago
    result = time_ago_text(timestamp)
    assert_equal "about 2 hours ago", result
  end

  test "time_ago_text formats days ago correctly" do
    timestamp = 3.days.ago
    result = time_ago_text(timestamp)
    assert_equal "3 days ago", result
  end

  test "truncate_description uses default length of 150" do
    long_text = "a" * 200
    result = truncate_description(long_text)
    assert result.length <= 153  # 150 + "..." = 153
    assert_includes result, "..."
  end

  test "truncate_description respects custom length" do
    long_text = "a" * 100
    result = truncate_description(long_text, length: 50)
    assert result.length <= 53  # 50 + "..." = 53
    assert_includes result, "..."
  end

  test "truncate_description returns original text if under limit" do
    short_text = "Short text"
    result = truncate_description(short_text)
    assert_equal short_text, result
  end

  test "count_nested_replies counts single level correctly" do
    replies = [
      { replies: [] },
      { replies: [] }
    ]
    result = count_nested_replies(replies)
    assert_equal 2, result
  end

  test "count_nested_replies counts nested levels correctly" do
    replies = [
      {
        replies: [
          { replies: [] },
          { replies: [] }
        ]
      },
      { replies: [] }
    ]
    result = count_nested_replies(replies)
    assert_equal 4, result  # 1 + (1 + 1) + 1 = 4
  end

  test "count_nested_replies handles empty array" do
    result = count_nested_replies([])
    assert_equal 0, result
  end

  test "count_nested_replies handles deeply nested structure" do
    replies = [
      {
        replies: [
          {
            replies: [
              { replies: [] }
            ]
          }
        ]
      }
    ]
    result = count_nested_replies(replies)
    assert_equal 3, result  # 1 + 1 + 1 = 3
  end

  test "format_date_value formats date correctly" do
    date_string = "2024-01-15"
    result = send(:format_date_value, date_string)
    assert_equal "January 15, 2024", result
  end

  test "format_date_value handles Date objects" do
    date = Date.new(2024, 6, 10)
    result = send(:format_date_value, date)
    assert_equal "June 10, 2024", result
  end

  test "format_date_value handles invalid dates gracefully" do
    invalid_date = "not a date"
    result = send(:format_date_value, invalid_date)
    assert_equal "not a date", result
  end

  test "format_date_value handles nil gracefully" do
    result = send(:format_date_value, nil)
    assert_equal "", result
  end
end
