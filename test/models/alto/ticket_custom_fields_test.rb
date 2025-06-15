require "test_helper"

module Alto
  class TicketCustomFieldsTest < ActiveSupport::TestCase
    def setup
      @user1 = users(:one)
      @status_set = alto_status_sets(:default)
      @board = alto_boards(:bugs)  # Using bugs board since general doesn't exist
      @bugs_board = alto_boards(:bugs)
    end

    test "should have field_values as JSON" do
      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "High",
          "steps_to_reproduce" => "Test steps",
          "priority" => "High",
          "browser" => "Chrome"
        }
      )

      assert_equal({
        "severity" => "High",
        "steps_to_reproduce" => "Test steps",
        "priority" => "High",
        "browser" => "Chrome"
      }, ticket.field_values)
    end

    test "should get field value by field object" do
      priority_field = @board.fields.create!(label: "Priority", field_type: "select", field_options: [ "Low", "High" ])
      browser_field = @board.fields.create!(label: "Browser", field_type: "select", field_options: [ "Chrome", "Safari" ])

      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Medium",
          "steps_to_reproduce" => "Test steps for field value",
          "priority" => "High",
          "browser" => "Safari"
        }
      )

      assert_equal "High", ticket.field_value(priority_field)
      assert_equal "Safari", ticket.field_value(browser_field)
    end

    test "should set field value by field object" do
      priority_field = @board.fields.create!(label: "Priority", field_type: "select", field_options: [ "Low", "High" ])
      browser_field = @board.fields.create!(label: "Browser", field_type: "select", field_options: [ "Chrome", "Firefox" ])

      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "severity" => "Low",
          "steps_to_reproduce" => "Basic test steps"
        }
      )

      ticket.set_field_value(priority_field, "High")
      ticket.set_field_value(browser_field, "Firefox")

      assert_equal "High", ticket.field_value(priority_field)
      assert_equal "Firefox", ticket.field_value(browser_field)
      assert_equal({
        "severity" => "Low",
        "steps_to_reproduce" => "Basic test steps",
        "priority" => "High",
        "browser" => "Firefox"
      }, ticket.field_values)
    end

    test "should process multiselect field arrays to comma-separated strings" do
      multiselect_field = @board.fields.create!(
        label: "Tags",
        field_type: "multiselect",
        field_options: ["Bug", "Feature", "Enhancement"],
        position: 0
      )

      ticket = Ticket.new(
        title: "Multiselect Test",
        description: "Testing multiselect processing",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "tags" => ["Bug", "Feature"]  # array format
        }
      )

      ticket.process_multiselect_fields!

      assert_equal "Bug,Feature", ticket.field_values["tags"]
    end

    test "should handle empty multiselect arrays" do
      multiselect_field = @board.fields.create!(
        label: "Categories",
        field_type: "multiselect",
        field_options: ["A", "B", "C"],
        position: 0
      )

      ticket = Ticket.new(
        title: "Empty Multiselect Test",
        description: "Testing empty multiselect",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "categories" => []  # empty array
        }
      )

      ticket.process_multiselect_fields!

      assert_equal "", ticket.field_values["categories"]
    end

    test "should filter blank values from multiselect arrays" do
      multiselect_field = @board.fields.create!(
        label: "Features",
        field_type: "multiselect",
        field_options: ["A", "B", "C"],
        position: 0
      )

      ticket = Ticket.new(
        title: "Blank Filter Test",
        description: "Testing blank value filtering",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "features" => ["A", "", "B", nil, "C"]  # mixed with blanks
        }
      )

      ticket.process_multiselect_fields!

      assert_equal "A,B,C", ticket.field_values["features"]
    end

    test "should skip non-multiselect fields in process_multiselect_fields" do
      text_field = @board.fields.create!(
        label: "Description",
        field_type: "text_field",
        position: 0
      )

      ticket = Ticket.new(
        title: "Non-multiselect Test",
        description: "Testing non-multiselect fields",
        user_id: @user1.id,
        board: @board,
        field_values: {
          "description" => ["This", "Should", "Stay", "Array"]  # should remain unchanged
        }
      )

      ticket.process_multiselect_fields!

      assert_equal ["This", "Should", "Stay", "Array"], ticket.field_values["description"]
    end

    test "should get custom_fields from board" do
      ticket = Ticket.create!(
        title: "Field Ticket",
        description: "Description",
        user_id: @user1.id,
        board: @bugs_board,
        field_values: {
          "severity" => "High",
          "steps_to_reproduce" => "Step 1, Step 2"
        }
      )

      assert_respond_to ticket, :custom_fields
      assert_equal ticket.board.fields.ordered, ticket.custom_fields
    end

    test "should validate required custom fields" do
      required_field = @bugs_board.fields.create!(
        label: "Required Field",
        field_type: "text_input",
        required: true
      )

      ticket = Ticket.new(
        title: "Missing Required Fields",
        description: "Description",
        user_id: @user1.id,
        board: @bugs_board
      )

      assert_not ticket.valid?
      assert_includes ticket.errors.attribute_names, :field_values_required_field
      assert_includes ticket.errors[:field_values_required_field], "Required Field is required"
    end

    test "should be valid when required fields are provided" do
      required_field = @bugs_board.fields.create!(
        label: "Required Field",
        field_type: "text_input",
        required: true
      )

      ticket = Ticket.new(
        title: "With Required Fields",
        description: "Description",
        user_id: @user1.id,
        board: @bugs_board,
        field_values: {
          "severity" => "High",
          "steps_to_reproduce" => "Step 1",
          "required_field" => "Value provided"
        }
      )

      assert ticket.valid?
    end
  end
end
