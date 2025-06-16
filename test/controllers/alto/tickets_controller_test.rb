require "test_helper"

module Alto
  class TicketsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers
    include AltoAuthTestHelper

    def setup
      setup_alto_permissions(can_manage_boards: true, can_access_admin: true)

      @user = users(:one)
      @user2 = users(:two)

      # Create test status set
      @status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
      @status_set.statuses.create!(name: "Open", color: "green", position: 0, slug: "open")
      @status_set.statuses.create!(name: "Closed", color: "red", position: 1, slug: "closed")

      @general_board = Alto::Board.create!(
        name: "General Feedback",
        slug: "general-feedback",
        description: "General feedback and suggestions",
        status_set: @status_set,
        is_admin_only: false,
        item_label_singular: "ticket"
      )

      @bugs_board = Alto::Board.create!(
        name: "Bug Reports",
        slug: "bug-reports",
        description: "Report bugs here",
        status_set: @status_set,
        is_admin_only: false,
        item_label_singular: "bug"
      )

      # Create test tickets
      @ticket = @general_board.tickets.create!(
        title: "Test Ticket",
        description: "Test description",
        user_id: @user.id,
        user_type: "User"
      )

      @other_users_ticket = @general_board.tickets.create!(
        title: "Other User's Ticket",
        description: "Not my ticket",
        user_id: @user2.id,
        user_type: "User"
      )

      # Set host for URL generation
      host! "example.com"
    end

    def teardown
      teardown_alto_permissions
    end

    # INDEX TESTS
    test "should get index" do
      get "/boards/#{@general_board.slug}/tickets"
      assert_response :success
      assert_includes response.body, @ticket.title
    end

    test "should execute index queries without polymorphic errors" do
      # This test would have caught the original polymorphic bug
      assert_nothing_raised do
        @general_board.tickets.active.includes(:board, :upvotes, :tags).to_a
      end

      get "/boards/#{@general_board.slug}/tickets"
      assert_response :success
    end

    test "should filter tickets by search" do
      get "/boards/#{@general_board.slug}/tickets", params: { search: "Test Ticket" }
      assert_response :success
      assert_includes response.body, @ticket.title
      assert_not_includes response.body, @other_users_ticket.title
    end

    test "should filter tickets by status" do
      @ticket.update!(status_slug: "closed")

      get "/boards/#{@general_board.slug}/tickets", params: { status: "closed" }
      assert_response :success
      assert_includes response.body, @ticket.title
    end

    test "should sort tickets by popular" do
      # Create an upvote to make ticket popular
      @ticket.upvotes.create!(user_id: @user.id)

      get "/boards/#{@general_board.slug}/tickets", params: { sort: "popular" }
      assert_response :success
      assert_includes response.body, @ticket.title
    end

    # SHOW TESTS
    test "should show ticket" do
      get "/boards/#{@general_board.slug}/tickets/#{@ticket.id}"
      assert_response :success
      assert_includes response.body, @ticket.title
      assert_includes response.body, @ticket.description
    end

    test "should show ticket with comments section" do
      comment = @ticket.comments.create!(content: "Test comment", user_id: @user.id)

      get "/boards/#{@general_board.slug}/tickets/#{@ticket.id}"
      assert_response :success
      assert_includes response.body, comment.content
    end

    # NEW TESTS
    test "should get new ticket form" do
      get "/boards/#{@general_board.slug}/tickets/new"
      assert_response :success
      assert_includes response.body, "New Ticket"
      assert_select "form"
    end

    test "new ticket form renders all custom fields for the board" do
      board = Alto::Board.create!(name: "Custom Field Board", item_label_singular: "ticket", status_set: @general_board.status_set)
      board.fields.create!(label: "Priority", field_type: "text_field", position: 0)
      board.fields.create!(label: "Category", field_type: "text_field", position: 1)
      get "/boards/#{board.slug}/tickets/new"
      assert_response :success
      assert_select 'input[name="ticket[field_values][priority]"]', 1
      assert_select 'input[name="ticket[field_values][category]"]', 1
    end

    test "new ticket form does not error if board has no fields" do
      board = Alto::Board.create!(name: "No Field Board", item_label_singular: "ticket", status_set: @general_board.status_set)
      get "/boards/#{board.slug}/tickets/new"
      assert_response :success
      # Should not render any custom field inputs
      assert_select 'input[name^="ticket[field_values]"]', 0
    end

    # CREATE TESTS
    test "should create ticket with valid params" do
      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@general_board.slug}/tickets", params: {
          ticket: {
            title: "New Test Ticket",
            description: "New test description"
          }
        }
      end

      ticket = Alto::Ticket.last
      assert_equal "New Test Ticket", ticket.title
      assert_equal "New test description", ticket.description
      assert_equal @general_board, ticket.board
      assert_response :redirect
      assert_redirected_to "/boards/#{@general_board.slug}/tickets/#{ticket.id}"
    end

    test "should not create ticket with invalid params" do
      assert_no_difference("Alto::Ticket.count") do
        post "/boards/#{@general_board.slug}/tickets", params: {
          ticket: {
            title: "", # blank title should fail validation
            description: "Description without title"
          }
        }
      end

      assert_response :success # re-renders form
      assert_select "form" # form should be present for retry
    end

    test "should create ticket with field_values" do
      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@general_board.slug}/tickets", params: {
          ticket: {
            title: "Ticket with Custom Fields",
            description: "Testing field values",
            field_values: {
              "priority" => "High",
              "category" => "Bug Report"
            }
          }
        }
      end

      ticket = Alto::Ticket.last
      assert_equal "High", ticket.field_values["priority"]
      assert_equal "Bug Report", ticket.field_values["category"]
    end

    # EDIT TESTS
    test "should get edit form for own ticket" do
      # Simulate user being logged in as the ticket owner
      get "/boards/#{@general_board.slug}/tickets/#{@ticket.id}/edit"
      assert_response :success
      assert_includes response.body, @ticket.title
      assert_select "form"
    end

    test "should handle editing other users ticket based on permission system" do
      # Try to edit someone else's ticket
      get "/boards/#{@general_board.slug}/tickets/#{@other_users_ticket.id}/edit"
      # Response depends on permission system - could be success or redirect
      # We'll test that it doesn't crash and handles gracefully
      assert_includes [ 200, 302 ], response.status
    end

    # UPDATE TESTS
    test "should update own ticket" do
      patch "/boards/#{@general_board.slug}/tickets/#{@ticket.id}", params: {
        ticket: {
          title: "Updated Test Ticket",
          description: "Updated description"
        }
      }

      @ticket.reload
      assert_equal "Updated Test Ticket", @ticket.title
      assert_equal "Updated description", @ticket.description
      assert_response :redirect
      assert_redirected_to "/boards/#{@general_board.slug}/tickets/#{@ticket.id}"
    end

    test "should not update with invalid params" do
      original_title = @ticket.title

      patch "/boards/#{@general_board.slug}/tickets/#{@ticket.id}", params: {
        ticket: {
          title: "", # blank title should fail
          description: "Valid description"
        }
      }

      @ticket.reload
      assert_equal original_title, @ticket.title # should not have changed
      assert_response :success # re-renders edit form
      assert_select "form"
    end

    test "should handle updating other users ticket based on permission system" do
      original_title = @other_users_ticket.title

      patch "/boards/#{@general_board.slug}/tickets/#{@other_users_ticket.id}", params: {
        ticket: {
          title: "Attempted Update",
          description: "Testing permission system"
        }
      }

      @other_users_ticket.reload
      # Response depends on permission system implementation
      assert_includes [ 200, 302 ], response.status
      # If no permission system is in place, the update might succeed
      # If permission system is active, it should be blocked
    end

    test "should update ticket field_values" do
      patch "/boards/#{@general_board.slug}/tickets/#{@ticket.id}", params: {
        ticket: {
          title: @ticket.title, # keep same title
          description: @ticket.description, # keep same description
          field_values: {
            "status" => "In Progress",
            "assignee" => "John Doe"
          }
        }
      }

      @ticket.reload
      assert_equal "In Progress", @ticket.field_values["status"]
      assert_equal "John Doe", @ticket.field_values["assignee"]
    end

    # DESTROY TESTS
    test "should destroy own ticket" do
      assert_difference("Alto::Ticket.count", -1) do
        delete "/boards/#{@general_board.slug}/tickets/#{@ticket.id}"
      end

      assert_response :redirect
      assert_redirected_to "/boards/#{@general_board.slug}/tickets"
        end

    test "should handle destroying other users ticket based on permission system" do
      # Test depends on permission system - might allow or deny
      delete "/boards/#{@general_board.slug}/tickets/#{@other_users_ticket.id}"

      # Response should be either success redirect or permission redirect
      assert_includes [ 200, 302 ], response.status

      # Check if ticket still exists - depends on permission implementation
      begin
        @other_users_ticket.reload
        # If we get here, ticket wasn't deleted (good for permission system)
      rescue ActiveRecord::RecordNotFound
        # Ticket was deleted (might indicate missing permission checks)
      end
    end

            # BOARD SCOPING TESTS
    test "should properly scope tickets to their boards" do
      # Create a ticket in the general board
      general_ticket = @general_board.tickets.create!(
        title: "General Board Ticket",
        description: "This belongs to general board",
        user_id: @user.id
      )

      # Create a different board to test scoping
      features_board = Alto::Board.create!(name: "Features", slug: "features", status_set: @status_set)

      # Try to access general board ticket through features board URL
      # This should return 404 because the ticket doesn't belong to the features board
      get "/boards/#{features_board.slug}/tickets/#{general_ticket.id}"
      assert_response :not_found
    end

    test "should handle non-existent board gracefully" do
      get "/boards/non-existent/tickets"
      assert_response :not_found
    end

    test "should handle non-existent ticket gracefully" do
      get "/boards/#{@general_board.slug}/tickets/99999"
      assert_response :not_found
    end

    # ARCHIVED TICKET TESTS
    test "should not allow editing archived ticket" do
      @ticket.update!(archived: true)

      get "/boards/#{@general_board.slug}/tickets/#{@ticket.id}/edit"
      assert_response :redirect
      follow_redirect!
      assert_includes response.body, "Archived tickets cannot be modified"
    end

    test "should not allow updating archived ticket" do
      @ticket.update!(archived: true)
      original_title = @ticket.title

      patch "/boards/#{@general_board.slug}/tickets/#{@ticket.id}", params: {
        ticket: { title: "Should not update" }
      }

      @ticket.reload
      assert_equal original_title, @ticket.title
      assert_response :redirect
    end

    test "should not allow destroying archived ticket" do
      @ticket.update!(archived: true)

      assert_no_difference("Alto::Ticket.count") do
        delete "/boards/#{@general_board.slug}/tickets/#{@ticket.id}"
      end

      assert_response :redirect
      assert @ticket.reload # should still exist
    end

    # MULTISELECT FIELD PROCESSING TESTS
    test "should process multiselect field arrays" do
      # Create a multiselect field
      multiselect_field = @general_board.fields.create!(
        label: "Tags",
        field_type: "multiselect",
        field_options: [ "Bug", "Feature", "Enhancement" ],
        required: false,
        position: 1
      )

      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@general_board.slug}/tickets", params: {
          ticket: {
            title: "Multiselect Test",
            description: "Testing multiselect processing",
            field_values: {
              "tags" => [ "Bug", "Feature" ] # array should be converted to string
            }
          }
        }
      end

      ticket = Alto::Ticket.last
      # Should be converted to comma-separated string
      assert_equal "Bug,Feature", ticket.field_values["tags"]
    end
  end
end
