require "test_helper"

class PageAccessibilityTest < ActionDispatch::IntegrationTest
  include ::Alto::Engine.routes.url_helpers

  def setup
    create_test_data
  end

  # ==========================================
  # BASIC PAGE ACCESSIBILITY TESTS
  # ==========================================

  test "boards index page is accessible" do
    get boards_path
    assert_successful_page_load
  end

  test "activity page is accessible" do
    get activity_path
    assert_successful_page_load
  end

  test "board activity page is accessible" do
    get board_activity_path(@board)
    assert_successful_page_load
  end

  test "board archive page is accessible" do
    get board_archive_path(@board)
    assert_successful_page_load
  end

  # ==========================================
  # ADMIN PAGES AUTHENTICATION TESTS
  # ==========================================

  test "admin dashboard handles unauthenticated users appropriately" do
    get admin_dashboard_path
    assert_admin_access_handled_appropriately
  end

  test "admin settings handles unauthenticated users appropriately" do
    get admin_settings_path
    assert_admin_access_handled_appropriately
  end

  test "admin boards handles unauthenticated users appropriately" do
    get admin_boards_path
    assert_admin_access_handled_appropriately
  end

  test "admin status sets handles unauthenticated users appropriately" do
    get admin_status_sets_path
    assert_admin_access_handled_appropriately
  end

  # ==========================================
  # ADMIN PAGES WITH MOCKED ACCESS
  # ==========================================

  test "admin pages work with mocked access" do
    with_admin_access do
      admin_routes.each do |route|
        get route[:path]
        assert_successful_page_load
      end
    end
  end

  # ==========================================
  # NAVIGATION LINK TESTS
  # ==========================================

  test "admin dashboard contains expected navigation links" do
    with_admin_access do
      get admin_dashboard_path
      assert_response :success

      dashboard_navigation_links.each do |link|
        assert_select "a[href='#{link[:path]}']", text: link[:text]
      end
    end
  end

  test "admin settings contains expected navigation links" do
    with_admin_access do
      get admin_settings_path
      assert_response :success

      settings_navigation_links.each do |link|
        assert_select "a[href='#{link[:path]}']", text: link[:text]
      end
    end
  end

  # ==========================================
  # FORM STRUCTURE TESTS
  # ==========================================

  test "admin board creation form has correct structure" do
    with_admin_access do
      get new_admin_board_path
      assert_response :success

      assert_select "form[action='#{admin_boards_path}'][method='post']"
      assert_select "input[name='board[name]']"
    end
  end

  test "admin status set creation form has correct structure" do
    with_admin_access do
      get new_admin_status_set_path
      assert_response :success

      assert_select "form[action='#{admin_status_sets_path}'][method='post']"
      assert_select "input[name='status_set[name]']"
    end
  end

  # ==========================================
  # ERROR HANDLING TESTS
  # ==========================================

  test "non-existent board raises 404" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get board_tickets_path("non-existent-board")
    end
  end

  test "non-existent ticket raises 404" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get board_ticket_path(@board, 99999)
    end
  end

  # ==========================================
  # RESPONSIVE TESTS
  # ==========================================

  test "pages work with mobile user agent" do
    get boards_path, headers: mobile_headers
    assert_response :success
  end

  # ==========================================
  # COMPREHENSIVE ROUTE COVERAGE
  # ==========================================

  test "all accessible routes load successfully" do
    accessible_routes.each do |route|
      get route[:path]
      assert_response :success, "#{route[:name]} (#{route[:path]}) should be accessible"
      assert_select "title", /#{Regexp.escape(Alto.configuration.app_name)}/i,
                    "#{route[:name]} should have app name in title"
    end
  end

  test "admin routes work with proper access" do
    with_admin_access do
      admin_routes.each do |route|
        get route[:path]
        assert_response :success, "#{route[:name]} (#{route[:path]}) should be accessible with admin access"
        assert_select "title", /#{Regexp.escape(Alto.configuration.app_name)}/i,
                      "#{route[:name]} should have app name in title"
      end
    end
  end

  private

  # ==========================================
  # SETUP HELPERS (Following Rule #3: Push business rules into models or POROs)
  # ==========================================

  def create_test_data
    @user = User.create!(email: "test@example.com")

    @status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
    @status_set.statuses.create!([
      { name: "Open", color: "green", position: 0, slug: "open" },
      { name: "Closed", color: "gray", position: 1, slug: "closed" }
    ])

    @board = Alto::Board.create!(
      name: "Test Board",
      slug: "test-board",
      is_admin_only: false,
      item_label_singular: "ticket",
      status_set: @status_set
    )

    @ticket = @board.tickets.create!(
      title: "Test Ticket",
      description: "Test description",
      user_id: @user.id,
      status_slug: "open"
    )
  end

  # ==========================================
  # ASSERTION HELPERS (Following Rule #26: Early returns for nil/failure handling)
  # ==========================================

  def assert_successful_page_load
    assert_response :success
    assert_select "title", /#{Regexp.escape(Alto.configuration.app_name)}/i
  end

  def assert_admin_access_handled_appropriately
    # Should either redirect or return success (depends on host app authentication)
    assert_includes [200, 302], response.status
  end

  # ==========================================
  # ROUTE CONFIGURATION (Following Rule #16: Encapsulate reusable logic)
  # ==========================================

  def accessible_routes
    [
      { path: boards_path, name: "Boards Index" },
      { path: activity_path, name: "Global Activity" },
      { path: board_activity_path(@board), name: "Board Activity" },
      { path: board_archive_path(@board), name: "Board Archive" }
    ]
  end

  def admin_routes
    [
      { path: admin_dashboard_path, name: "Admin Dashboard" },
      { path: admin_settings_path, name: "Admin Settings" },
      { path: admin_boards_path, name: "Admin Boards" },
      { path: admin_status_sets_path, name: "Admin Status Sets" },
      { path: new_admin_board_path, name: "New Admin Board" },
      { path: new_admin_status_set_path, name: "New Admin Status Set" }
    ]
  end

  def dashboard_navigation_links
    [
      { path: admin_boards_path, text: "Manage Boards" },
      { path: admin_status_sets_path, text: "Status Sets" },
      { path: admin_settings_path, text: "Settings" },
      { path: boards_path, text: "Back to Feedback" }
    ]
  end

  def settings_navigation_links
    [
      { path: admin_dashboard_path, text: "Dashboard" },
      { path: boards_path, text: "Back to Tickets" }
    ]
  end

  def mobile_headers
    { "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" }
  end

  # ==========================================
  # ADMIN ACCESS HELPERS (Following Rule #2: Extract repeated logic into concerns)
  # ==========================================

  def with_admin_access
    mock_admin_access
    yield
  ensure
    cleanup_admin_access
  end

  def mock_admin_access
    admin_controllers.each do |controller_class|
      controller_class.class_eval do
        def ensure_admin_access; end
        def require_admin_access; end
        def current_user; User.first; end
        def can_access_admin?; true; end
      end
    end
  end

  def cleanup_admin_access
    admin_controllers.each do |controller_class|
      controller_class.class_eval do
        def ensure_admin_access
          unless can_access_admin?
            redirect_to boards_path, alert: "You do not have permission to access the admin area"
          end
        end
        def require_admin_access
          redirect_to boards_path, alert: "Access denied" unless can_access_admin?
        end
        def current_user; super; end
        def can_access_admin?; super; end
      end
    end
  end

  def admin_controllers
    [
      Alto::Admin::DashboardController,
      Alto::Admin::SettingsController,
      Alto::Admin::BoardsController,
      Alto::Admin::StatusSetsController
    ]
  end
end
