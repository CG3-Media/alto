require "test_helper"

class Alto::UpvoteTogglerTest < ActiveSupport::TestCase
  def setup
    # Create status_set first (following Rule #3: real objects)
    @status_set = Alto::StatusSet.find_or_create_by(id: 1) do |ss|
      ss.name = "Default Status Set"
      ss.description = "Default status set for testing"
      ss.is_default = true
    end

    # Create status for the board
    @status = Alto::Status.find_or_create_by(slug: "open", status_set: @status_set) do |s|
      s.name = "Open"
      s.color = "green"
      s.position = 0
    end

    # Create user for tickets
    @user = User.find_or_create_by(email: "test@example.com") do |u|
      u.name = "Test User"
    end

    @board = Alto::Board.find_by(slug: "general-feedback") || Alto::Board.create!(
      name: "General Feedback",
      slug: "general-feedback",
      description: "Test board",
      status_set: @status_set
    )
    @ticket = Alto::Ticket.create!(
      title: "Test Ticket",
      description: "Test description",
      board: @board,
      status_slug: "open",
      user: @user
    )
    @comment = Alto::Comment.create!(
      ticket: @ticket,
      content: "Test comment",
      user: @user
    )
  end

  test "toggle creates upvote when none exists for ticket" do
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    result = toggler.toggle

    assert result.success
    assert_equal true, result.upvoted
    assert_equal 1, @ticket.upvotes.count
  end

  test "toggle creates upvote when none exists for comment" do
    toggler = Alto::UpvoteToggler.new(@comment, @user)

    result = toggler.toggle

    assert result.success
    assert_equal true, result.upvoted
    assert_equal 1, @comment.upvotes.count
  end

  test "toggle removes upvote when one exists for ticket" do
    # Create existing upvote
    @ticket.upvotes.create!(user_id: @user.id, user_type: "User")

    toggler = Alto::UpvoteToggler.new(@ticket, @user)
    result = toggler.toggle

    assert result.success
    assert_equal false, result.upvoted
    assert_equal 0, @ticket.upvotes.count
  end

  test "toggle removes upvote when one exists for comment" do
    # Create existing upvote
    @comment.upvotes.create!(user_id: @user.id, user_type: "User")

    toggler = Alto::UpvoteToggler.new(@comment, @user)
    result = toggler.toggle

    assert result.success
    assert_equal false, result.upvoted
    assert_equal 0, @comment.upvotes.count
  end

  test "toggle handles multiple toggles correctly" do
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    # First toggle - create
    result1 = toggler.toggle
    assert_equal true, result1.upvoted
    assert_equal 1, @ticket.upvotes.count

    # Second toggle - remove
    result2 = toggler.toggle
    assert_equal false, result2.upvoted
    assert_equal 0, @ticket.upvotes.count

    # Third toggle - create again
    result3 = toggler.toggle
    assert_equal true, result3.upvoted
    assert_equal 1, @ticket.upvotes.count
  end

  test "toggle works with different users independently" do
    user2 = User.find_or_create_by(email: "user2@example.com") do |u|
      u.name = "User 2"
    end

    toggler1 = Alto::UpvoteToggler.new(@ticket, @user)
    toggler2 = Alto::UpvoteToggler.new(@ticket, user2)

    # User 1 upvotes
    result1 = toggler1.toggle
    assert_equal true, result1.upvoted
    assert_equal 1, @ticket.upvotes.count

    # User 2 also upvotes
    result2 = toggler2.toggle
    assert_equal true, result2.upvoted
    assert_equal 2, @ticket.upvotes.count

    # User 1 removes upvote
    result3 = toggler1.toggle
    assert_equal false, result3.upvoted
    assert_equal 1, @ticket.upvotes.count

    # User 2's upvote should still exist
    assert @ticket.upvotes.exists?(user_id: user2.id)
  end

  test "find_existing_upvote returns correct upvote" do
    upvote = @ticket.upvotes.create!(user_id: @user.id, user_type: "User")
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    result = toggler.send(:find_existing_upvote)

    assert_equal upvote, result
  end

  test "find_existing_upvote returns nil when no upvote exists" do
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    result = toggler.send(:find_existing_upvote)

    assert_nil result
  end

  test "add_upvote returns success structure" do
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    result = toggler.send(:add_upvote)

    assert result.success
    assert_equal true, result.upvoted
  end

  test "remove_upvote returns success structure" do
    upvote = @ticket.upvotes.create!(user_id: @user.id, user_type: "User")
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    result = toggler.send(:remove_upvote, upvote)

    assert result.success
    assert_equal false, result.upvoted
  end

  test "add_upvote handles validation errors gracefully" do
    toggler = Alto::UpvoteToggler.new(@ticket, @user)

    # Mock the upvotable to simulate validation error
    mock_upvotes = Object.new
    mock_upvotes.define_singleton_method(:create!) do |attrs|
      raise ActiveRecord::RecordInvalid.new(Alto::Upvote.new)
    end

    @ticket.define_singleton_method(:upvotes) { mock_upvotes }

    result = toggler.send(:add_upvote)

    assert_equal false, result.success
    assert_not_nil result.error
  end
end
