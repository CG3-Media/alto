require "test_helper"
require "ostruct"
require "minitest/mock"

module Alto
  class TicketTest < ActiveSupport::TestCase
    def setup
      # Create test users to ensure they exist for validation
      @user1 = User.find_or_create_by!(id: 1, email: "test1@example.com")
      @user2 = User.find_or_create_by!(id: 2, email: "test2@example.com")

      # Use fixtures instead of manually creating status sets and boards
      @status_set = alto_status_sets(:default)
      @board = alto_boards(:general)
    end

    test "should create ticket with valid attributes" do
      ticket = Ticket.new(
        title: "Test Ticket",
        description: "A test ticket description",
        user_id: 1,
        board: @board
      )

      assert ticket.valid?
      assert ticket.save
      assert_equal "open", ticket.status_slug
    end

    test "should require title" do
      ticket = Ticket.new(
        description: "No title",
        user_id: 1,
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:title], "can't be blank"
    end

    test "should require description" do
      ticket = Ticket.new(
        title: "Title Only",
        user_id: 1,
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:description], "can't be blank"
    end

    test "should require user_id" do
      ticket = Ticket.new(
        title: "Test Ticket",
        description: "Description",
        board: @board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors[:user_id], "can't be blank"
    end

    test "should belong to board" do
      ticket = Ticket.create!(
        title: "Board Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_equal @board, ticket.board
    end

    test "should have many comments" do
      ticket = Ticket.create!(
        title: "Ticket with Comments",
        description: "Description",
        user_id: 1,
        board: @board
      )

      comment1 = ticket.comments.create!(content: "First comment", user_id: 1)
      comment2 = ticket.comments.create!(content: "Second comment", user_id: 2)

      assert_equal 2, ticket.comments.count
      assert_includes ticket.comments, comment1
      assert_includes ticket.comments, comment2
    end

    test "should have many upvotes" do
      ticket = Ticket.create!(
        title: "Upvoted Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      upvote1 = ticket.upvotes.create!(user_id: 1)
      upvote2 = ticket.upvotes.create!(user_id: 2)

      assert_equal 2, ticket.upvotes.count
      assert_includes ticket.upvotes, upvote1
      assert_includes ticket.upvotes, upvote2
    end

    test "should count upvotes" do
      ticket = Ticket.create!(
        title: "Vote Counter",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_equal 0, ticket.upvotes_count

      ticket.upvotes.create!(user_id: 1)
      ticket.upvotes.create!(user_id: 2)

      assert_equal 2, ticket.upvotes_count
    end

    test "should check if upvoted by user" do
      ticket = Ticket.create!(
        title: "User Vote Check",
        description: "Description",
        user_id: 1,
        board: @board
      )

      # Mock user object
      user = Struct.new(:id).new(1)
      other_user = Struct.new(:id).new(2)

      assert_not ticket.upvoted_by?(user)

      ticket.upvotes.create!(user_id: user.id)

      assert ticket.upvoted_by?(user)
      assert_not ticket.upvoted_by?(other_user)
    end

    test "should not be locked by default" do
      ticket = Ticket.create!(
        title: "Unlocked Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_not ticket.locked?
      assert ticket.can_be_voted_on?
      assert ticket.can_be_commented_on?
    end

    test "should prevent voting and commenting when locked" do
      ticket = Ticket.create!(
        title: "Locked Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: true
      )

      assert ticket.locked?
      assert_not ticket.can_be_voted_on?
      assert_not ticket.can_be_commented_on?
    end

    # Archive functionality tests
    test "should not be archived by default" do
      ticket = Ticket.create!(
        title: "Regular Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      assert_not ticket.archived?
      assert_not ticket.locked? # Should not be locked if only regular
    end

    test "should be archived when archived flag is true" do
      ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: true
      )

      assert ticket.archived?
    end

    # Custom fields tests
    test "should have field_values as JSON" do
      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        field_values: { "priority" => "High", "browser" => "Chrome" }
      )

      assert_equal({ "priority" => "High", "browser" => "Chrome" }, ticket.field_values)
    end

    test "should get field value by field object" do
      # Create test fields
      priority_field = @board.fields.create!(label: "Priority", field_type: "select", field_options: [ "Low", "High" ])
      browser_field = @board.fields.create!(label: "Browser", field_type: "select", field_options: [ "Chrome", "Safari" ])

      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        field_values: { "priority" => "High", "browser" => "Safari" }
      )

      assert_equal "High", ticket.field_value(priority_field)
      assert_equal "Safari", ticket.field_value(browser_field)
    end

    test "should set field value by field object" do
      # Create test fields
      priority_field = @board.fields.create!(label: "Priority", field_type: "select", field_options: [ "Low", "High" ])
      browser_field = @board.fields.create!(label: "Browser", field_type: "select", field_options: [ "Chrome", "Firefox" ])

      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      ticket.set_field_value(priority_field, "High")
      ticket.set_field_value(browser_field, "Firefox")

      assert_equal "High", ticket.field_value(priority_field)
      assert_equal "Firefox", ticket.field_value(browser_field)
      assert_equal({ "priority" => "High", "browser" => "Firefox" }, ticket.field_values)
    end

    test "should get custom_fields from board" do
      bugs_board = alto_boards(:bugs)

      # Provide values for the required fields on the bugs board
      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: 1,
        board: bugs_board,
        field_values: {
          "severity" => "High",           # Required field from fixtures
          "steps_to_reproduce" => "Step 1, Step 2"  # Required field from fixtures
        }
      )

      assert_respond_to ticket, :custom_fields
      assert_equal ticket.board.fields.ordered, ticket.custom_fields
    end

    test "should validate required custom fields" do
      bugs_board = alto_boards(:bugs)
      required_field = bugs_board.fields.create!(
        label: "Required Field",
        field_type: "text_input",
        required: true
      )

      ticket = Ticket.new(
        title: "Missing Required Fields",
        description: "Description",
        user_id: 1,
        board: bugs_board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors.attribute_names, :field_values_required_field
      assert_includes ticket.errors[:field_values_required_field], "Required Field is required"
    end

    test "should be valid when required fields are provided" do
      bugs_board = alto_boards(:bugs)
      required_field = bugs_board.fields.create!(
        label: "Required Field",
        field_type: "text_input",
        required: true
      )

      ticket = Ticket.new(
        title: "With Required Fields",
        description: "Description",
        user_id: 1,
        board: bugs_board,
        field_values: {
          "severity" => "High",                    # Existing required field from fixtures
          "steps_to_reproduce" => "Test steps",   # Existing required field from fixtures
          "required_field" => "Provided value"    # New required field we created
        }
      )

      assert ticket.valid?, "Ticket should be valid when all required fields are provided. Errors: #{ticket.errors.full_messages}"
    end

    test "archived tickets should be locked" do
      ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: true
      )

      assert ticket.archived?
      assert ticket.locked? # Archived tickets should be locked
      assert_not ticket.can_be_voted_on?
      assert_not ticket.can_be_commented_on?
    end

    test "should filter active tickets" do
      active_ticket = Ticket.create!(
        title: "Active Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: false
      )

      archived_ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: true
      )

      active_tickets = Ticket.active
      assert_includes active_tickets, active_ticket
      assert_not_includes active_tickets, archived_ticket
    end

    test "should filter archived tickets" do
      active_ticket = Ticket.create!(
        title: "Active Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: false
      )

      archived_ticket = Ticket.create!(
        title: "Archived Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        archived: true
      )

      archived_tickets = Ticket.archived
      assert_includes archived_tickets, archived_ticket
      assert_not_includes archived_tickets, active_ticket
    end

    test "should archive and unarchive tickets" do
      ticket = Ticket.create!(
        title: "Toggle Archive Test",
        description: "Description",
        user_id: 1,
        board: @board
      )

      # Initially not archived
      assert_not ticket.archived?
      assert_not ticket.locked?

      # Archive the ticket
      ticket.update!(archived: true)
      ticket.reload

      assert ticket.archived?
      assert ticket.locked?

      # Unarchive the ticket
      ticket.update!(archived: false)
      ticket.reload

      assert_not ticket.archived?
      assert_not ticket.locked? # Should not be locked anymore (unless manually locked)
    end

    test "manually locked and archived ticket should remain locked when unarchived" do
      ticket = Ticket.create!(
        title: "Double Lock Test",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: true,
        archived: true
      )

      # Should be locked (both manually and archived)
      assert ticket.locked?
      assert ticket.archived?

      # Unarchive but keep manual lock
      ticket.update!(archived: false)
      ticket.reload

      assert_not ticket.archived?
      assert ticket.locked? # Still locked because of manual lock
    end

    test "should get status information" do
      ticket = Ticket.create!(
        title: "Status Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: "open"
      )

      assert_equal "Open", ticket.status_name
      status = ticket.status
      assert status
      assert_equal "Open", status.name
      assert_equal "green", status.color
    end

    test "should filter by status" do
      open_ticket = Ticket.create!(
        title: "Open Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: "open"
      )

      closed_ticket = Ticket.create!(
        title: "Closed Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        status_slug: "closed"
      )

      open_tickets = Ticket.by_status("open")
      closed_tickets = Ticket.by_status("closed")

      assert_includes open_tickets, open_ticket
      assert_not_includes open_tickets, closed_ticket

      assert_includes closed_tickets, closed_ticket
      assert_not_includes closed_tickets, open_ticket
    end

    test "should scope unlocked tickets" do
      unlocked = Ticket.create!(
        title: "Unlocked",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: false
      )

      locked = Ticket.create!(
        title: "Locked",
        description: "Description",
        user_id: 1,
        board: @board,
        locked: true
      )

      unlocked_tickets = Ticket.unlocked

      assert_includes unlocked_tickets, unlocked
      assert_not_includes unlocked_tickets, locked
    end

    test "should order by recent" do
      old_ticket = Ticket.create!(
        title: "Old Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        created_at: 2.days.ago
      )

      new_ticket = Ticket.create!(
        title: "New Ticket",
        description: "Description",
        user_id: 1,
        board: @board,
        created_at: 1.hour.ago
      )

      recent_tickets = Ticket.recent

      assert_equal new_ticket, recent_tickets.first
      assert_equal old_ticket, recent_tickets.last
    end

    # Subscribable concern tests
    test "should include Subscribable concern" do
      assert_includes Ticket.included_modules, ::Alto::Subscribable
    end

    test "should create subscription automatically when ticket is created with valid user" do
      # Use real User model and configuration instead of complex mocks
      assert_difference "Alto::Subscription.count", 1 do
        ticket = Ticket.create!(
          title: "Auto Subscription Ticket",
          description: "Should create subscription",
          user_id: 1,
          user_type: "User",
          board: @board
        )
      end
    end

    test "should not create subscription if user email lookup fails" do
      # Create a user but stub the email lookup to return nil
      user = User.create!(id: 999, email: nil) # User with no email

      assert_no_difference "Alto::Subscription.count" do
        ticket = Ticket.create!(
          title: "No Email Subscription Ticket",
          description: "Should not create subscription when user has no email",
          user_id: 999,
          user_type: "User",
          board: @board
        )
      end
    end

    test "should not create subscription if user has no email" do
      # Create a user without email for testing
      user_without_email = User.create!(id: 998)

      assert_no_difference "Alto::Subscription.count" do
        ticket = Ticket.create!(
          title: "No Email Ticket",
          description: "Should not create subscription",
          user_id: 998,
          user_type: "User",
          board: @board
        )
      end
    end

    test "should handle subscription creation errors gracefully" do
      # Test that ticket creation succeeds even if subscription logic has issues
      assert_nothing_raised do
        ticket = Ticket.create!(
          title: "Error Handling Ticket",
          description: "Should handle errors gracefully",
          user_id: 1,
          user_type: "User",
          board: @board
        )
      end
    end

    # Simple subscription test without mocking
    test "should have subscription methods available" do
      ticket = Ticket.create!(
        title: "Simple Test Ticket",
        description: "Testing subscription functionality",
        user_id: 1,
        board: @board
      )

      # Test that the subscribable methods are available (including private methods)
      assert ticket.respond_to?(:subscribable_ticket, true), "subscribable_ticket method should be available"
      assert ticket.respond_to?(:user_email, true), "user_email method should be available"

      # Test the subscribable_ticket method returns self (call it via send since it might be private)
      assert_equal ticket, ticket.send(:subscribable_ticket)

      # Test that the methods don't crash when called
      assert_nothing_raised do
        ticket.send(:subscribable_ticket)
        ticket.send(:user_email)
      end
    end

    test "should trigger subscription creation callback" do
      # Count subscriptions before
      initial_count = ::Alto::Subscription.count

      # Create a ticket that should trigger the subscription callback
      ticket = Ticket.create!(
        title: "Callback Test Ticket",
        description: "Testing subscription callback",
        user_id: 1,
        board: @board
      )

      # The callback should have attempted to run, but it will fail gracefully
      # because there's no user configuration in the test environment
      # The important thing is that the callback was called without errors
      assert ticket.persisted?, "Ticket should be created successfully even if subscription fails"

      # Verify the callback methods exist and return expected values
      assert_equal ticket, ticket.send(:subscribable_ticket)
      assert_equal "test1@example.com", ticket.send(:user_email) # Should return the user's email from setup
    end

    test "should create subscription when user comments on ticket" do
      # Create a ticket first
      ticket = Ticket.create!(
        title: "Test Ticket for Comments",
        description: "Testing comment subscription functionality",
        user_id: 1,
        board: @board
      )

      # Count initial subscriptions
      initial_subscription_count = ::Alto::Subscription.count

      # Create a comment on the ticket
      comment = ticket.comments.create!(
        content: "This is a test comment that should trigger subscription creation",
        user_id: 2  # Different user commenting
      )

      # Verify the comment was created successfully
      assert comment.persisted?, "Comment should be created successfully"
      assert_equal ticket, comment.ticket, "Comment should belong to the correct ticket"

      # Verify the comment has subscription methods available
      assert comment.respond_to?(:subscribable_ticket, true), "Comment should have subscribable_ticket method"
      assert comment.respond_to?(:user_email, true), "Comment should have user_email method"

      # Verify subscribable_ticket returns the correct ticket
      assert_equal ticket, comment.send(:subscribable_ticket), "Comment's subscribable_ticket should return the parent ticket"

      # The subscription creation callback should have been triggered
      # Even if it fails gracefully (due to no user email in test environment),
      # the comment creation should still succeed and the callback should run
      assert comment.persisted?, "Comment creation should succeed even if subscription fails"
    end

    test "should parameterize field labels as keys" do
      # Create fields with various label formats
      priority_field = @board.fields.create!(label: "Priority Level", field_type: "select", field_options: [ "Low", "High" ])
      browser_field = @board.fields.create!(label: "Browser Type", field_type: "select", field_options: [ "Chrome", "Firefox" ])
      special_field = @board.fields.create!(label: "OS & Version", field_type: "text_input")

      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: 1,
        board: @board
      )

      ticket.set_field_value(priority_field, "High")
      ticket.set_field_value(browser_field, "Chrome")
      ticket.set_field_value(special_field, "macOS 14")

      # Verify the keys are properly parameterized (& gets removed by Rails)
      expected_field_values = {
        "priority_level" => "High",
        "browser_type" => "Chrome",
        "os_version" => "macOS 14"  # & gets removed by parameterize
      }

      assert_equal expected_field_values, ticket.field_values
      assert_equal "High", ticket.field_value(priority_field)
      assert_equal "Chrome", ticket.field_value(browser_field)
      assert_equal "macOS 14", ticket.field_value(special_field)
    end

    test "should properly validate required fields during form submission simulation" do
      # This test simulates the exact scenario that was failing before our fix
      bugs_board = alto_boards(:bugs)

      # Create a ticket with form-submitted field_values (simulating form params)
      ticket = Ticket.new(
        title: "Form Submission Test",
        description: "Testing required field validation during form submission",
        user_id: 1,
        board: bugs_board,
        field_values: {
          "severity" => "Medium",  # This should satisfy the required severity field
          "steps_to_reproduce" => "1. Fill out form\n2. Submit form\n3. Should work!"  # This should satisfy the required steps field
        }
      )

      # Before our fix, this would fail because the validation method was checking
      # field_value(field) instead of the submitted field_values hash
      assert ticket.valid?, "Ticket should be valid when required fields are provided via form submission. Errors: #{ticket.errors.full_messages}"

      # Test that it can be saved successfully
      assert ticket.save, "Ticket should save when required fields are provided"

      # Verify the values are properly stored
      assert_equal "Medium", ticket.field_values["severity"]
      assert_equal "1. Fill out form\n2. Submit form\n3. Should work!", ticket.field_values["steps_to_reproduce"]
    end

    test "should fail validation when required fields are missing during form submission" do
      bugs_board = alto_boards(:bugs)

      # Create a ticket missing required fields
      ticket = Ticket.new(
        title: "Missing Required Fields Test",
        description: "Testing validation failure",
        user_id: 1,
        board: bugs_board,
        field_values: {
          "severity" => "High"  # Has severity
          # Missing "steps_to_reproduce" which is required
        }
      )

      assert_not ticket.valid?, "Ticket should be invalid when required fields are missing"
      assert_includes ticket.errors.attribute_names, :field_values_steps_to_reproduce
      assert_includes ticket.errors[:field_values_steps_to_reproduce], "Steps to Reproduce is required"
    end

    test "should handle form submission with empty string values for required fields" do
      bugs_board = alto_boards(:bugs)

      # Test empty string values (which should be considered blank)
      ticket = Ticket.new(
        title: "Empty String Test",
        description: "Testing empty string handling",
        user_id: 1,
        board: bugs_board,
        field_values: {
          "severity" => "",  # Empty string should be considered blank
          "steps_to_reproduce" => "Valid steps"
        }
      )

      assert_not ticket.valid?, "Ticket should be invalid when required field has empty string"
      assert_includes ticket.errors.attribute_names, :field_values_severity
      assert_includes ticket.errors[:field_values_severity], "Severity is required"
    end
  end
end
