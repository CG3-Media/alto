require "test_helper"

module Alto
  class CustomFieldsTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def setup
      # Create test objects directly for integration test
      @user = User.find_or_create_by!(email: "test1@example.com")

      status_set = Alto::StatusSet.find_or_create_by!(name: "Test Status Set") do |ss|
        ss.is_default = true
      end
      status_set.statuses.find_or_create_by!(slug: "open") do |s|
        s.name = "Open"
        s.color = "green"
        s.position = 0
      end

      @bugs_board = Alto::Board.find_or_create_by!(slug: "bug-reports") do |board|
        board.name = "Bug Reports"
        board.description = "Report bugs here"
        board.status_set = status_set
        board.is_admin_only = false
        board.item_label_singular = "bug"
      end

      # Clear existing fields to avoid conflicts
      @bugs_board.fields.destroy_all

      # Configure Alto permissions for testing
      ::Alto.configure do |config|
        config.permission :can_access_alto? do
          true
        end
        config.permission :can_submit_tickets? do
          true
        end
        config.permission :can_access_board? do |board|
          true
        end
      end

      # Create required fields for testing - use arrays, serialization will handle JSON conversion
      @severity_field = @bugs_board.fields.create!(
        label: "Severity",
        field_type: "select_field",
        field_options: [ "Low", "Medium", "High", "Critical" ],  # Array, not JSON string
        required: true,
        position: 0
      )

      @steps_field = @bugs_board.fields.create!(
        label: "Steps to Reproduce",
        field_type: "text_area",
        placeholder: "Please list the steps to reproduce this issue...",
        required: true,
        position: 1
      )

      # Mock current_user for testing
      user = @user
      ::Alto::ApplicationController.define_method(:current_user) do
        user
      end

      # Set host for URL generation
      host! "example.com"
    end

    test "should create ticket with valid custom fields" do
      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@bugs_board.slug}/tickets", params: {
          ticket: {
            title: "Valid Bug Report",
            description: "This should work",
            field_values: {
              "severity" => "High",
              "steps_to_reproduce" => "1. Do something\n2. Bug happens"
            }
          }
        }
      end

      ticket = Alto::Ticket.last
      assert_equal "High", ticket.field_values["severity"]
      assert_equal "1. Do something\n2. Bug happens", ticket.field_values["steps_to_reproduce"]
      assert_response :redirect
    end

    test "should accept any field_values without unpermitted parameter errors" do
      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@bugs_board.slug}/tickets", params: {
          ticket: {
            title: "Custom Fields Test",
            description: "Testing parameter permissions",
            field_values: {
              "severity" => "Medium",
              "steps_to_reproduce" => "Steps here",
              "random_field" => "Should be accepted",
              "another_field" => "Also accepted"
            }
          }
        }
      end

      ticket = Alto::Ticket.last
      assert_equal "Medium", ticket.field_values["severity"]
      assert_equal "Steps here", ticket.field_values["steps_to_reproduce"]
      assert_equal "Should be accepted", ticket.field_values["random_field"]
      assert_equal "Also accepted", ticket.field_values["another_field"]
    end

    test "should fail validation when required fields are missing" do
      assert_no_difference("Alto::Ticket.count") do
        post "/boards/#{@bugs_board.slug}/tickets", params: {
          ticket: {
            title: "Missing Required Fields",
            description: "This should fail validation",
            field_values: {
              "severity" => "High"
              # missing required "steps_to_reproduce" field
            }
          }
        }
      end

      assert_response :success  # re-renders the form
      assert_match /Steps to Reproduce is required/i, response.body
    end

    test "should fail validation when required fields are empty" do
      assert_no_difference("Alto::Ticket.count") do
        post "/boards/#{@bugs_board.slug}/tickets", params: {
          ticket: {
            title: "Empty Required Fields",
            description: "This should fail validation",
            field_values: {
              "severity" => "",  # empty required field
              "steps_to_reproduce" => "Valid steps"
            }
          }
        }
      end

      assert_response :success  # re-renders the form
      assert_match /Severity is required/i, response.body
    end

    test "should handle multiselect arrays correctly" do
      # Create a multiselect field
      multiselect_field = @bugs_board.fields.create!(
        label: "Affected Components",
        field_type: "multiselect_field",
        field_options: [ "UI", "API", "Database" ],  # Array, not JSON string
        required: false,
        position: 3
      )

      assert_difference("Alto::Ticket.count") do
        post "/boards/#{@bugs_board.slug}/tickets", params: {
          ticket: {
            title: "Multiselect Test",
            description: "Testing multiselect handling",
            field_values: {
              "severity" => "Low",
              "steps_to_reproduce" => "Test steps",
              "affected_components" => [ "UI", "API" ]  # array for multiselect
            }
          }
        }
      end

      ticket = Alto::Ticket.last
      # Should be converted to comma-separated string
      assert_equal "UI,API", ticket.field_values["affected_components"]
    end
  end
end
