require "test_helper"

module Alto
  class FieldTest < ActiveSupport::TestCase
    def setup
      @board = alto_boards(:bugs)
      @field_attributes = {
        board: @board,
        label: "Severity",
        field_type: "select",
        field_options: [ "Low", "Medium", "High", "Critical" ],
        required: true
      }
    end

    test "should create field with valid attributes" do
      field = Field.new(@field_attributes)
      assert field.valid?
      assert field.save
    end

    test "should require label" do
      field = Field.new(@field_attributes.except(:label))
      assert_not field.valid?
      assert_includes field.errors[:label], "can't be blank"
    end

    test "should require field_type" do
      field = Field.new(@field_attributes.except(:field_type))
      assert_not field.valid?
      assert_includes field.errors[:field_type], "can't be blank"
    end

    test "should require board" do
      field = Field.new(@field_attributes.except(:board))
      assert_not field.valid?
      assert_includes field.errors[:board], "must exist"
    end

    test "should validate field_type enum" do
      field = Field.new(@field_attributes)

      # Valid enum values should work
      field.field_type = "select"
      assert field.valid?

      # Invalid enum values should raise ArgumentError
      assert_raises(ArgumentError) do
        field.field_type = "invalid_type"
      end
    end

    test "should auto-set position when not provided" do
      # Create a clean board for this test
      clean_board = Alto::Board.create!(name: "Test Board", slug: "test-position", status_set: @board.status_set)

      field = Field.create!(@field_attributes.merge(board: clean_board))
      assert_equal 0, field.position

      field2 = Field.create!(@field_attributes.merge(board: clean_board, label: "Priority"))
      assert_equal 1, field2.position
    end

    test "should allow manual position setting" do
      field = Field.create!(@field_attributes.merge(position: 5))
      assert_equal 5, field.position
    end

    test "select fields should require options" do
      field = Field.new(@field_attributes.merge(field_options: []))
      assert_not field.valid?
      assert_includes field.errors[:field_options], "must be provided for select fields"
    end

    test "multiselect fields should require options" do
      field = Field.new(@field_attributes.merge(field_type: "multiselect", field_options: []))
      assert_not field.valid?
      assert_includes field.errors[:field_options], "must be provided for multiselect fields"
    end

    test "text fields should not require options" do
      field = Field.new(@field_attributes.merge(field_type: "text_input", field_options: nil))
      assert field.valid?
    end

    test "options_array should return array for select fields" do
      field = Field.new(@field_attributes)
      assert_equal [ "Low", "Medium", "High", "Critical" ], field.options_array
    end

    test "options_array should return empty array for non-select fields" do
      field = Field.new(@field_attributes.merge(field_type: "text_input", field_options: nil))
      assert_equal [], field.options_array
    end

    test "needs_options? should return true for select and multiselect" do
      select_field = Field.new(field_type: "select")
      multiselect_field = Field.new(field_type: "multiselect")
      text_field = Field.new(field_type: "text_input")

      assert select_field.needs_options?
      assert multiselect_field.needs_options?
      assert_not text_field.needs_options?
    end

    test "should be ordered by position scope" do
      # Create a clean board for this test to avoid fixture interference
      clean_board = Alto::Board.create!(name: "Test Board", slug: "test-ordering", status_set: @board.status_set)

      field1 = Field.create!(@field_attributes.merge(board: clean_board, position: 2, label: "Second"))
      field2 = Field.create!(@field_attributes.merge(board: clean_board, position: 0, label: "First"))
      field3 = Field.create!(@field_attributes.merge(board: clean_board, position: 1, label: "Middle"))

      ordered_fields = clean_board.fields.ordered
      assert_equal [ "First", "Middle", "Second" ], ordered_fields.map(&:label)
    end

    test "required_fields scope should return only required fields" do
      required_field = Field.create!(@field_attributes.merge(required: true))
      optional_field = Field.create!(@field_attributes.merge(required: false, label: "Optional"))

      required_fields = Field.required_fields
      assert_includes required_fields, required_field
      assert_not_includes required_fields, optional_field
    end
  end
end
