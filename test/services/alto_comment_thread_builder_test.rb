require "test_helper"

class Alto::CommentThreadBuilderTest < ActiveSupport::TestCase
  def setup
    # Use fixtures instead of manual creation
    @user = users(:one)
    @board = alto_boards(:bugs)

    @ticket = Alto::Ticket.create!(
      title: "Test Ticket",
      description: "Test description",
      board: @board,
      status_slug: "open",
      user: @user,
      field_values: {
        "severity" => "high",
        "steps_to_reproduce" => "Test comment thread builder steps"
      }
    )
    @builder = Alto::CommentThreadBuilder.new(@ticket)
  end

  test "build_thread_for_comment returns comment with reply tree" do
    root_comment = Alto::Comment.create!(
      ticket: @ticket,
      content: "Root comment",
      user: @user
    )

    result = @builder.build_thread_for_comment(root_comment)

    assert_equal root_comment, result[:comment]
    assert_respond_to result[:replies], :each
  end

  test "redirect_path_for_reply with root comment returns ticket with anchor" do
    comment = Alto::Comment.create!(
      ticket: @ticket,
      content: "Root comment",
      user: @user
    )

    path = @builder.redirect_path_for_reply(comment, @board, @ticket)

    assert_equal [@board, @ticket, { anchor: "comment-#{comment.id}" }], path
  end

  test "redirect_path_for_reply with reply comment returns thread root path" do
    parent = Alto::Comment.create!(
      ticket: @ticket,
      content: "Parent comment",
      user: @user
    )
    reply = Alto::Comment.create!(
      ticket: @ticket,
      content: "Reply body",
      user: @user,
      parent_id: parent.id
    )

    path = @builder.redirect_path_for_reply(reply, @board, @ticket)

    assert_equal [@board, @ticket, parent], path
  end

  test "redirect_path_for_failed_reply with parent_id returns thread root path" do
    parent = Alto::Comment.create!(ticket: @ticket, content: "Parent comment", user: @user)
    comment_params = { parent_id: parent.id }

    path = @builder.redirect_path_for_failed_reply(comment_params, @ticket, @board)

    assert_equal [@board, @ticket, parent], path
  end

  test "redirect_path_for_failed_reply without parent_id returns nil" do
    comment_params = {}

    path = @builder.redirect_path_for_failed_reply(comment_params, @ticket, @board)

    assert_nil path
  end

  test "redirect_path_for_failed_reply with blank parent_id returns nil" do
    comment_params = { parent_id: "" }

    path = @builder.redirect_path_for_failed_reply(comment_params, @ticket, @board)

    assert_nil path
  end

  test "redirect_path_for_delete root comment in thread view returns ticket" do
    comment = Alto::Comment.create!(ticket: @ticket, content: "Test comment", user: @user)
    referrer = "/boards/general/tickets/1/comments/#{comment.id}"

    path = @builder.redirect_path_for_delete(comment, @board, @ticket, referrer)

    assert_equal [@board, @ticket], path
  end

  test "redirect_path_for_delete reply comment in thread view returns thread root" do
    parent = Alto::Comment.create!(ticket: @ticket, content: "Parent comment", user: @user)
    reply = Alto::Comment.create!(
      ticket: @ticket,
      content: "Reply body",
      user: @user,
      parent_id: parent.id
    )
    referrer = "/boards/general/tickets/1/comments/#{reply.id}"

    path = @builder.redirect_path_for_delete(reply, @board, @ticket, referrer)

    assert_equal [@board, @ticket, parent], path
  end

  test "redirect_path_for_delete not in thread view returns ticket" do
    comment = Alto::Comment.create!(ticket: @ticket, content: "Test comment", user: @user)
    referrer = "/boards/general/tickets/1"

    path = @builder.redirect_path_for_delete(comment, @board, @ticket, referrer)

    assert_equal [@board, @ticket], path
  end

  test "redirect_path_for_delete with nil referrer returns ticket" do
    comment = Alto::Comment.create!(ticket: @ticket, content: "Test comment", user: @user)

    path = @builder.redirect_path_for_delete(comment, @board, @ticket, nil)

    assert_equal [@board, @ticket], path
  end

  test "in_thread_view? returns true when referrer contains /comments/" do
    builder = Alto::CommentThreadBuilder.new(@ticket)
    referrer = "/boards/general/tickets/1/comments/123"

    result = builder.send(:in_thread_view?, referrer)

    assert_equal true, result
  end

  test "in_thread_view? returns false when referrer does not contain /comments/" do
    builder = Alto::CommentThreadBuilder.new(@ticket)
    referrer = "/boards/general/tickets/1"

    result = builder.send(:in_thread_view?, referrer)

    assert_equal false, result
  end

  test "in_thread_view? returns false when referrer is nil" do
    builder = Alto::CommentThreadBuilder.new(@ticket)

    result = builder.send(:in_thread_view?, nil)

    assert_equal false, result
  end

  test "handles deeply nested reply chain correctly" do
    # Create a chain: root -> reply1 -> reply2
    root = Alto::Comment.create!(ticket: @ticket, content: "Root comment", user: @user)
    reply1 = Alto::Comment.create!(
      ticket: @ticket,
      content: "First reply",
      user: @user,
      parent_id: root.id
    )
    reply2 = Alto::Comment.create!(
      ticket: @ticket,
      content: "Second reply",
      user: @user,
      parent_id: reply1.id
    )

    # Test that deeply nested reply still points to root
    path = @builder.redirect_path_for_reply(reply2, @board, @ticket)
    assert_equal [@board, @ticket, root], path
  end

  test "build_thread_includes_nested_replies" do
    root = Alto::Comment.create!(ticket: @ticket, content: "Root", user: @user)
    reply = Alto::Comment.create!(
      ticket: @ticket,
      content: "Reply",
      user: @user,
      parent_id: root.id
    )

    result = @builder.build_thread_for_comment(root)

    assert_equal root, result[:comment]
    assert_equal 1, result[:replies].length
    assert_equal reply, result[:replies].first[:comment]
  end

  test "handles comment deletion path determination" do
    comment = Alto::Comment.create!(ticket: @ticket, content: "Test", user: @user)

    # Test thread view
    thread_referrer = "/boards/test/tickets/1/comments/#{comment.id}"
    thread_path = @builder.redirect_path_for_delete(comment, @board, @ticket, thread_referrer)
    assert_equal [@board, @ticket], thread_path

    # Test non-thread view
    ticket_referrer = "/boards/test/tickets/1"
    ticket_path = @builder.redirect_path_for_delete(comment, @board, @ticket, ticket_referrer)
    assert_equal [@board, @ticket], ticket_path
  end
end
