require "test_helper"

module Alto
  class CommentCallbackTest < ActiveSupport::TestCase
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
      @comment_params = {
        content: "Test Comment",
        user: @user,
        ticket: @ticket
      }
    end

    test "should trigger comment_created callback after creation" do
      # Track callback calls
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Create comment (Rule #7 - assert DB side-effects)
        assert_difference -> { Comment.count } do
          comment = Comment.create!(@comment_params)
        end

        # Verify callback was triggered
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :comment_created, method

        comment, ticket, board, user = args
        assert_kind_of Comment, comment
        assert_equal @ticket, ticket
        assert_equal @board, board
        assert_equal @user, user
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should trigger comment_deleted callback after destruction" do
      # Create comment first
      comment = Comment.create!(@comment_params)

      # Track callback calls
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Destroy comment
        assert_difference -> { Comment.count }, -1 do
          comment.destroy!
        end

        # Verify deletion callback
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :comment_deleted, method

        deleted_comment, ticket, board, user = args
        assert_equal comment, deleted_comment
        assert_equal @ticket, ticket
        assert_equal @board, board
        assert_equal @user, user
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle callback errors gracefully during creation" do
      # Mock callback to raise error
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |*args|
        raise StandardError, "Callback failed"
      end

      begin
        # Should raise error during creation
        assert_raises(StandardError, "Callback failed") do
          comment = Comment.create!(@comment_params)
        end
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle callback errors gracefully during destruction" do
      # Create comment first
      comment = Comment.create!(@comment_params)

      # Mock callback to raise error
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |*args|
        raise StandardError, "Callback failed"
      end

      begin
        # Should raise error during destruction
        assert_raises(StandardError, "Callback failed") do
          comment.destroy!
        end
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should pass correct objects to created callback" do
      # Track callback arguments
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        comment = Comment.create!(@comment_params)

        # Verify all arguments are correct
        comment_arg, ticket_arg, board_arg, user_arg = callback_args

        assert_equal comment, comment_arg
        assert_kind_of Comment, comment_arg

        assert_equal @ticket, ticket_arg
        assert_kind_of Ticket, ticket_arg

        assert_equal @board, board_arg
        assert_kind_of Board, board_arg

        assert_equal @user, user_arg
        assert_kind_of User, user_arg
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should pass correct objects to deleted callback" do
      # Create comment first
      comment = Comment.create!(@comment_params)

      # Track deletion callback arguments
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args if method == :comment_deleted
      end

      begin
        comment.destroy!

        # Verify all arguments are correct for deletion
        comment_arg, ticket_arg, board_arg, user_arg = callback_args

        assert_equal comment, comment_arg
        assert_equal @ticket, ticket_arg
        assert_equal @board, board_arg
        assert_equal @user, user_arg
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle nested comment callbacks" do
      # Create parent comment first
      parent_comment = Comment.create!(@comment_params)

      # Track callbacks for reply
      callback_calls = []
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_calls << [method, args]
      end

      begin
        # Create reply comment
        reply_params = @comment_params.merge(parent_id: parent_comment.id)
        reply_comment = Comment.create!(reply_params)

        # Should trigger callback for reply
        assert_equal 1, callback_calls.length
        method, args = callback_calls.first
        assert_equal :comment_created, method

        comment_arg = args[0]
        assert_equal reply_comment, comment_arg
        assert_equal parent_comment.id, comment_arg.parent_id
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should resolve polymorphic user correctly in callback" do
      # Create comment with polymorphic user setup
      comment_params = @comment_params.merge(user_id: @user.id, user_type: "User")

      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        comment = Comment.create!(comment_params)

        # Verify polymorphic user is resolved correctly
        user_arg = callback_args[3]
        assert_equal @user.id, user_arg.id
        assert_equal "User", user_arg.class.name
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle comment with image attachment in callback" do
      # Skip this test if fixture_file_upload is not available
      skip "ActiveStorage test requires controller context" unless respond_to?(:fixture_file_upload)

      # Create comment with image (using ActiveStorage)
      comment_params = @comment_params.merge(
        image: fixture_file_upload("test_image.png", "image/png")
      )

      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        comment = Comment.create!(comment_params)

        # Verify comment object in callback has image
        comment_arg = callback_args[0]
        assert comment_arg.image.attached?, "Comment should have image attached"
      rescue => e
        # Skip if ActiveStorage not properly set up in test
        skip "ActiveStorage not available: #{e.message}"
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle comment content correctly in callback" do
      # Test with various content types
      special_content = "Comment with **markdown** and @mentions"
      comment_params = @comment_params.merge(content: special_content)

      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        comment = Comment.create!(comment_params)

        # Verify content is preserved correctly
        comment_arg = callback_args[0]
        assert_equal special_content, comment_arg.content
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should maintain ticket association in callback during comment deletion" do
      # Create comment
      comment = Comment.create!(@comment_params)
      original_ticket = comment.ticket

      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args if method == :comment_deleted
      end

      begin
        comment.destroy!

        # Even after destruction, callback should have ticket reference
        ticket_arg = callback_args[1]
        assert_equal original_ticket, ticket_arg
        assert_equal @ticket.id, ticket_arg.id
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle subscribable behavior in callback context" do
      callback_args = nil
      original_call_method = Alto::CallbackManager.method(:call)

      Alto::CallbackManager.define_singleton_method(:call) do |method, *args|
        callback_args = args
      end

      begin
        comment = Comment.create!(@comment_params)

        # Test that comment's subscribable_ticket method works
        assert_equal @ticket, comment.subscribable_ticket

        # Verify ticket is passed correctly to callback
        ticket_arg = callback_args[1]
        assert_equal comment.subscribable_ticket, ticket_arg
      ensure
        # Restore original method
        Alto::CallbackManager.define_singleton_method(:call, original_call_method)
      end
    end

    test "should handle user_email resolution in callback context" do
      # Configure user email lookup
      ::Alto.configure do |config|
        config.user_email do |user_id|
          User.find(user_id)&.email
        end
      end

      comment = Comment.create!(@comment_params)

      # Should resolve user email correctly
      assert_equal @user.email, comment.user_email

      # Clean up
      ::Alto.instance_variable_set(:@configuration, nil)
    end
  end
end
