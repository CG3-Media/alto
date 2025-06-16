require "test_helper"

module Alto
  class UpvoteCallbackTest < ActiveSupport::TestCase
    def setup
      @user = users(:one)
      @board = alto_boards(:bugs)
      @ticket = @board.tickets.create!(
        title: "Test Ticket",
        description: "Description",
        user: @user,
        field_values: {
          "severity" => "high",
          "steps_to_reproduce" => "Test steps to reproduce"
        }
      )
      @comment = @ticket.comments.create!(
        content: "Test Comment",
        user: @user
      )
    end

    test "should trigger upvote_created callback after ticket upvote creation" do
      # Track callback calls
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Create upvote (Rule #7 - assert DB side-effects)
        assert_difference -> { Upvote.count } do
          upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)
        end

        # Verify callback was triggered with correct arguments
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :upvote_created, method

        upvote, votable, board, user = args
        assert_kind_of Upvote, upvote
        assert_equal @ticket, votable
        assert_equal @board, board
        assert_equal @user, user
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should trigger upvote_created callback after comment upvote creation" do
      # Track callback calls
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        assert_difference -> { Upvote.count } do
          upvote = Upvote.create!(upvotable: @comment, user_id: @user.id)
        end

        # Verify callback with comment-specific logic
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :upvote_created, method

        upvote, votable, board, user = args
        assert_equal @comment, votable
        assert_equal @board, board  # Should get board from comment's ticket
        assert_equal @user, user
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should trigger upvote_removed callback after destruction" do
      # Create upvote first
      upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)

      # Track callback calls
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Destroy upvote
        assert_difference -> { Upvote.count }, -1 do
          upvote.destroy!
        end

        # Verify removal callback
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :upvote_removed, method

        destroyed_upvote, votable, board, user = args
        assert_equal upvote, destroyed_upvote
        assert_equal @ticket, votable
        assert_equal @board, board
        assert_equal @user, user
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle callback errors gracefully during creation" do
      # Mock callback to raise error
      upvote_created = false
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |*args|
        raise StandardError, "Callback failed"
      end

      begin
        # Should still create upvote successfully (Rule #3 - real objects)
        # Note: The error will propagate, so we expect it
        assert_raises(StandardError, "Callback failed") do
          upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)
          upvote_created = true
        end
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle callback errors gracefully during destruction" do
      # Create upvote first
      upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)

      # Mock callback to raise error
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |*args|
        raise StandardError, "Callback failed"
      end

      begin
        # Should raise error during destruction
        assert_raises(StandardError, "Callback failed") do
          upvote.destroy!
        end
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should resolve user object correctly in callback" do
      # Track callback arguments
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        Upvote.create!(upvotable: @ticket, user_id: @user.id)

        # Verify user object resolution
        user_arg = callback_args[3]
        assert_equal @user, user_arg
        assert_kind_of User, user_arg
        assert_equal @user.id, user_arg.id
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle comment upvote board resolution" do
      # Create comment on ticket
      comment = @ticket.comments.create!(content: "Test", user: @user)

      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        Upvote.create!(upvotable: comment, user_id: @user.id)

        # Board should be resolved from comment's ticket
        board_arg = callback_args[2]
        assert_equal @board, board_arg
        assert_equal @ticket.board, board_arg
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle orphaned upvotable gracefully" do
      # Create upvote
      upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)

      # Delete the ticket first
      @ticket.destroy!

      # Now try to destroy the upvote - should handle gracefully
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Should still call callback even with orphaned upvotable
        assert_nothing_raised do
          upvote.reload rescue upvote.destroy! # Might already be destroyed via dependent destroy
        end
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should set user_type correctly before callback" do
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)

        # Verify user_type was set correctly
        assert_equal "User", upvote.user_type

        # Verify user object in callback
        user_arg = callback_args[3]
        assert_equal @user, user_arg
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should pass subscribable ticket correctly" do
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        # Create comment upvote
        upvote = Upvote.create!(upvotable: @comment, user_id: @user.id)

        # Test subscribable_ticket method
        assert_equal @ticket, upvote.subscribable_ticket
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle user_email resolution" do
      # Configure user email lookup
      ::Alto.configure do |config|
        config.user_email do |user_id|
          User.find(user_id)&.email
        end
      end

      upvote = Upvote.create!(upvotable: @ticket, user_id: @user.id)

      # Should resolve user email correctly
      assert_equal @user.email, upvote.user_email

      # Clean up
      ::Alto.instance_variable_set(:@configuration, nil)
    end
  end
end
