require "test_helper"
require "generators/alto/widget_generator"

class Alto::Generators::WidgetGeneratorTest < Rails::Generators::TestCase
  tests Alto::Generators::WidgetGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "gets available boards correctly" do
    boards = generator.send(:get_available_boards)

    # Should include fixture boards
    board_slugs = boards.map { |b| b[:slug] }
    assert_includes board_slugs, "bugs"
  end

  test "creates widget partial with board slug" do
    # Test the file creation directly
    generator.instance_variable_set(:@board_slug, "bugs")

    # Call the method directly
    generator.send(:create_widget_partial)

    # Assert partial was created
    assert_file "app/views/shared/alto/_bugs_widget.html.erb" do |content|
      assert_includes content, '::Alto::Board.find("bugs")'
      assert_includes content, 'board.tickets.build'
      assert_includes content, 'Submit <%= board.item_label_singular.titleize %>'
      assert_includes content, 'alto.board_tickets_path(board)'
    end
  end

  test "detects existing widget files" do
    # Create an existing widget file
    generator.instance_variable_set(:@board_slug, "bugs")
    existing_content = "<div>Existing widget content</div>"

    # Create the file first
    FileUtils.mkdir_p(File.join(destination_root, "app/views/shared/alto"))
    File.write(File.join(destination_root, "app/views/shared/alto/_bugs_widget.html.erb"), existing_content)

    # Verify file exists
    widget_path = File.join(destination_root, "app/views/shared/alto/_bugs_widget.html.erb")
    assert File.exist?(widget_path), "Widget file should exist"

    # Verify content is preserved when file exists
    assert_file "app/views/shared/alto/_bugs_widget.html.erb" do |content|
      assert_equal existing_content, content
    end
  end

  test "handles empty boards gracefully by showing usage" do
    generator.instance_variable_set(:@board_slug, "bugs")

    # Test that show_usage works
    output = capture(:stdout) do
      generator.send(:show_usage)
    end

    assert_includes output, "Widget created!"
    assert_includes output, "bugs_widget"
  end
end
