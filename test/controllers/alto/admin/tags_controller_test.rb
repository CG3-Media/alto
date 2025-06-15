require "test_helper"

module Alto
  module Admin
    class TagsControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      def setup
        # Use fixtures following Rails test rule #2
        @user = users(:one)
        @board = alto_boards(:bugs)
        @feature_tag = alto_tags(:feature)
        @bug_tag = alto_tags(:bug)
        @unused_tag = alto_tags(:enhancement)  # Has 0 usage_count in fixtures
        @ticket = alto_tickets(:test_ticket)

        # Setup auth permissions
        setup_alto_permissions(can_manage_boards: true, can_access_admin: true)
      end

      def teardown
        teardown_alto_permissions
      end

      # INDEX Tests
      test "redirects without board management permission" do
        setup_alto_permissions(can_manage_boards: false)

        get admin_board_tags_path(@board)
        assert_response :redirect
      end

      test "shows tags index with permission" do
        get admin_board_tags_path(@board)
        assert_response :success
        assert_select "h1", /tags/i
        assert_select "table"
      end

      test "shows tag statistics on index" do
        get admin_board_tags_path(@board)
        assert_response :success

                # Should show usage counts in the table cells (board uses "bug" as item name)
        assert_match /2 bugs/, response.body # feature tag usage
        assert_match /1 bug/, response.body # bug tag usage
        assert_match /0 bugs/, response.body # unused tag usage
      end

      # Note: There is no show action for tags in the routes

      # NEW Tests
      test "shows new tag form with permission" do
        get new_admin_board_tag_path(@board)
        assert_response :success
        assert_select "form"
        assert_select "input[name='tag[name]']"
        assert_select "input[name='tag[color]']"
      end

      test "redirects new without permission" do
        setup_alto_permissions(can_access_admin: false)

        get new_admin_board_tag_path(@board)
        assert_response :redirect
      end

      # CREATE Tests
      test "creates tag with valid params" do
        assert_difference -> { @board.tags.count } do
          post admin_board_tags_path(@board), params: {
            tag: { name: "new-tag", color: "#FF5733" }
          }
        end

        assert_response :redirect
        tag = @board.tags.find_by(name: "new-tag")
        assert_not_nil tag
        assert_equal "#FF5733", tag.color
        assert_equal "new-tag", tag.slug
        follow_redirect!
        assert_match /successfully created/i, response.body
      end

      test "does not create tag with invalid params" do
        assert_no_difference -> { @board.tags.count } do
          post admin_board_tags_path(@board), params: {
            tag: { name: "", color: "invalid" }
          }
        end

        assert_response :unprocessable_entity
        assert_select "form"
      end

      test "redirects create without permission" do
        setup_alto_permissions(can_access_admin: false)

        post admin_board_tags_path(@board), params: {
          tag: { name: "test", color: "#000000" }
        }
        assert_response :redirect
      end

      # EDIT Tests
      test "shows edit tag form with permission" do
        get edit_admin_board_tag_path(@board, @feature_tag)
        assert_response :success
        assert_select "form"
        assert_select "input[value='feature']"
      end

      test "redirects edit without permission" do
        setup_alto_permissions(can_access_admin: false)

        get edit_admin_board_tag_path(@board, @feature_tag)
        assert_response :redirect
      end

      # UPDATE Tests
      test "updates tag with valid params" do
        patch admin_board_tag_path(@board, @feature_tag), params: {
          tag: { name: "updated-feature", color: "#123456" }
        }

        assert_response :redirect
        @feature_tag.reload
        assert_equal "updated-feature", @feature_tag.name
        assert_equal "#123456", @feature_tag.color
        follow_redirect!
        assert_match /successfully updated/i, response.body
      end

      test "does not update tag with invalid params" do
        original_name = @feature_tag.name

        patch admin_board_tag_path(@board, @feature_tag), params: {
          tag: { name: "", color: "invalid" }
        }

        assert_response :unprocessable_entity
        @feature_tag.reload
        assert_equal original_name, @feature_tag.name
      end

      test "redirects update without permission" do
        setup_alto_permissions(can_access_admin: false)

        patch admin_board_tag_path(@board, @feature_tag), params: {
          tag: { name: "hacked" }
        }
        assert_response :redirect
      end

      # DESTROY Tests
      test "destroys unused tag" do
        assert_difference -> { @board.tags.count }, -1 do
          delete admin_board_tag_path(@board, @unused_tag)
        end

        assert_response :redirect
        follow_redirect!
        assert_match /successfully deleted/i, response.body
      end

      test "does not destroy used tag without force" do
        assert_no_difference -> { @board.tags.count } do
          delete admin_board_tag_path(@board, @feature_tag)
        end

        assert_response :redirect
        follow_redirect!
        assert_match /Cannot delete tag.*used by.*Use.*Force Delete/i, response.body
      end

      test "destroys used tag with force parameter" do
        assert_difference -> { @board.tags.count }, -1 do
          delete admin_board_tag_path(@board, @feature_tag), params: { force: "true" }
        end

        assert_response :redirect
        follow_redirect!
        assert_match /successfully deleted/i, response.body
      end

      test "redirects destroy without permission" do
        setup_alto_permissions(can_access_admin: false)

        delete admin_board_tag_path(@board, @unused_tag)
        assert_response :redirect
      end

      # ERROR HANDLING Tests
      test "handles nonexistent board" do
        nonexistent_id = 99999

        get admin_board_tags_path(nonexistent_id)
        assert_response :not_found
      end

      test "handles nonexistent tag" do
        nonexistent_slug = "nonexistent-tag-slug"

        get edit_admin_board_tag_path(@board, nonexistent_slug)
        assert_response :not_found
      end

      # EDGE CASE Tests
      test "creates tag with auto-generated slug" do
        post admin_board_tags_path(@board), params: {
          tag: { name: "special-tag", color: "#FF5733" }
        }

        tag = @board.tags.find_by(name: "special-tag")
        assert_not_nil tag
        assert_equal "special-tag", tag.slug
      end

      test "handles duplicate tag names" do
        post admin_board_tags_path(@board), params: {
          tag: { name: "feature", color: "#FF5733" }
        }

        assert_response :unprocessable_entity
        assert_select "form"
      end
    end
  end
end
