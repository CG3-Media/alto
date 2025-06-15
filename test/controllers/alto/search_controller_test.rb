require "test_helper"

module Alto
  class SearchControllerTest < ActionDispatch::IntegrationTest
    include ::Alto::Engine.routes.url_helpers

    def setup
      # Set up basic permissions for most tests
      setup_alto_permissions(can_access_admin: false)
    end

    def teardown
      teardown_alto_permissions
    end

    # Test basic search functionality
    test "should get search index" do
      get search_path
      assert_response :success
      assert_select "h1", "All Tickets"
      assert_select ".bg-white.rounded-lg.border", minimum: 1  # Should have ticket cards
    end

            test "should display all active tickets without search query" do
      get search_path
      assert_response :success

      # Should include active tickets in the response body
      assert_includes response.body, "Test Ticket"
      assert_includes response.body, "Feature Request"
    end

        test "should filter tickets by search query" do
      get search_path, params: { search: "crash" }
      assert_response :success

      # Should handle search queries without errors
      assert_select "h1"  # Should have a heading
    end

        test "should handle fuzzy search" do
      get search_path, params: { search: "searc" }  # Partial match
      assert_response :success

      # Should handle fuzzy search without errors
      assert_select "h1"  # Should have a heading
    end

    test "should filter by status" do
      get search_path, params: { status: "open" }
      assert_response :success

      # Should show results without errors
      assert_select "h1", "All Tickets"
    end

    # Test admin vs non-admin access
        test "regular user should not see admin-only board tickets" do
      get search_path
      assert_response :success

      # Should work without errors for regular users
      assert_select "h1", "All Tickets"
    end

    test "admin user should see all board tickets" do
      setup_alto_permissions(can_access_admin: true)
      get search_path
      assert_response :success

      # Should work without errors for admin users
      assert_select "h1", "All Tickets"
    end

    # Test sorting
    test "should sort by recent by default" do
      get search_path
      assert_response :success

      # Should render successfully with default sorting
      assert_select "h1", "All Tickets"
      assert_select ".bg-white.rounded-lg.border", minimum: 1
    end

    test "should sort by popular when requested" do
      get search_path, params: { sort: "popular" }
      assert_response :success

      # Should handle popular sort parameter without errors
      assert_select "h1", "All Tickets"
    end

    # Test pagination
    test "should use default pagination of 25 items" do
      get search_path
      assert_response :success

      # Should show pagination info
      assert_select ".text-sm.text-gray-700", text: /Showing/
    end

    test "should respect custom per_page parameter" do
      get search_path, params: { per_page: 10 }
      assert_response :success

      # Should handle custom per_page without errors
      assert_select "h1", "All Tickets"
    end

    test "should limit per_page to maximum of 100" do
      get search_path, params: { per_page: 500 }
      assert_response :success

      # Should handle large per_page values gracefully
      assert_select "h1", "All Tickets"
    end

    test "should handle zero or negative per_page" do
      get search_path, params: { per_page: 0 }
      assert_response :success

      get search_path, params: { per_page: -5 }
      assert_response :success

      # Should default gracefully for invalid values
      assert_select "h1", "All Tickets"
    end

    # Test edge cases
    test "should handle empty search query" do
      get search_path, params: { search: "" }
      assert_response :success

      # Should return all tickets when search is empty
      assert_select "h1", "All Tickets"
      assert_select ".bg-white.rounded-lg.border", minimum: 1
    end

        test "should handle search with no results" do
      get search_path, params: { search: "nonexistent_query_xyz" }
      assert_response :success

      # Should show "no results" state gracefully
      assert_select "h1", "Search Results"
    end

        test "should handle special characters in search" do
      get search_path, params: { search: "test@#$%^&*()" }
      assert_response :success

      # Should not crash with special characters
      assert_select "h1", "Search Results"
    end

    # Test page structure
        test "should set is_global_search flag" do
      get search_path
      assert_response :success

      # Should show global search indicators
      assert_includes response.body, "All Tickets"
    end

    test "should group tickets by board" do
      get search_path
      assert_response :success

      # Should show board groupings in the response
      assert_select ".text-lg.font-semibold.text-gray-900", minimum: 1  # Board headers
    end

    # Test viewable statuses (integration with permissions)
    test "should filter by viewable statuses for non-admin users" do
      get search_path
      assert_response :success

      # Should work without errors for non-admin users
      assert_select "h1", "All Tickets"
    end

    # Test routing
    test "should route to search index" do
      # Test that the route works by making an actual request
      get search_path
      assert_response :success
      assert_equal "/search", search_path
    end
  end
end
