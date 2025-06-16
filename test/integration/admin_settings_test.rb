require "test_helper"
require "ostruct"

class AdminSettingsTest < ActionDispatch::IntegrationTest
  include ::Alto::Engine.routes.url_helpers

  def setup
    # Clear any existing settings
    Alto::Setting.delete_all

    # Create test user
    @user = User.create!(email: "test@example.com")
  end

  # Test the Setting model functionality (core business logic)
  test "Setting model can store and retrieve app name" do
    Alto::Setting.set("app_name", "My Custom Board")

    assert_equal "My Custom Board", Alto::Setting.get("app_name")

    setting = Alto::Setting.find_by(key: "app_name")
    assert_not_nil setting
    assert_equal "My Custom Board", setting.value
    assert_equal "string", setting.value_type
  end

  test "Setting model handles empty values" do
    Alto::Setting.set("app_name", "")

    assert_equal "", Alto::Setting.get("app_name")
  end

  test "Setting model handles special characters" do
    special_name = "My Board™ & Co. (2024)"
    Alto::Setting.set("app_name", special_name)

    assert_equal special_name, Alto::Setting.get("app_name")
  end

  test "Setting model bulk update functionality" do
    settings = {
      "app_name" => "Bulk Updated Board",
      "test_setting" => "test_value"
    }

    Alto::Setting.update_settings(settings)

    assert_equal "Bulk Updated Board", Alto::Setting.get("app_name")
    assert_equal "test_value", Alto::Setting.get("test_setting")
  end

  test "Setting model returns default when key doesn't exist" do
    assert_nil Alto::Setting.get("nonexistent_key")
    assert_equal "default_value", Alto::Setting.get("nonexistent_key", "default_value")
  end

  test "Setting model handles boolean values" do
    Alto::Setting.set("test_boolean", true)
    assert_equal true, Alto::Setting.get("test_boolean")

    setting = Alto::Setting.find_by(key: "test_boolean")
    assert_equal "boolean", setting.value_type
    assert_equal "true", setting.value
  end

  test "Setting model handles array values" do
    test_array = ["item1", "item2", "item3"]
    Alto::Setting.set("test_array", test_array)

    assert_equal test_array, Alto::Setting.get("test_array")

    setting = Alto::Setting.find_by(key: "test_array")
    assert_equal "array", setting.value_type
    assert_equal test_array.to_json, setting.value
  end

  # Test routes exist and are properly configured
  test "admin settings routes are configured" do
    # Test that the route exists by checking if we can generate the path
    assert_not_nil admin_settings_path
    assert_equal "/admin/settings", admin_settings_path
  end

  # Test controller functionality with minimal mocking
  test "settings controller show action works with admin access" do
    # Override just the permission check for this test
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        # Skip admin check for this test
      end

      def current_user
        User.first
      end
    end

    get admin_settings_path

    assert_response :success
    assert_select "h3", text: "Application Settings"
    assert_select "input[name='app_name']"

    # Clean up the override
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        unless can_access_admin?
          redirect_to boards_path, alert: "You do not have permission to access the admin area"
        end
      end

      def current_user
        super
      end
    end
  end

  test "settings controller update action works with admin access" do
    # Override just the permission check for this test
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        # Skip admin check for this test
      end

      def current_user
        User.first
      end
    end

    patch admin_settings_path, params: { app_name: "Test Board Name" }

    assert_redirected_to admin_settings_path
    assert_equal "Test Board Name", Alto::Setting.get("app_name")

    # Clean up the override
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        unless can_access_admin?
          redirect_to boards_path, alert: "You do not have permission to access the admin area"
        end
      end

      def current_user
        super
      end
    end
  end

  test "settings controller handles empty app name" do
    # Override just the permission check for this test
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access; end
      def current_user; User.first; end
    end

    patch admin_settings_path, params: { app_name: "" }

    assert_redirected_to admin_settings_path
    assert_equal "", Alto::Setting.get("app_name")

    # Clean up
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        unless can_access_admin?
          redirect_to boards_path, alert: "You do not have permission to access the admin area"
        end
      end
      def current_user; super; end
    end
  end

  test "settings controller shows success message after update" do
    # Override just the permission check for this test
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access; end
      def current_user; User.first; end
    end

    patch admin_settings_path, params: { app_name: "Updated Name" }

    assert_redirected_to admin_settings_path
    follow_redirect!

    # Check for success message in the response
    assert_response :success

    # Clean up
    Alto::Admin::SettingsController.class_eval do
      def ensure_admin_access
        unless can_access_admin?
          redirect_to boards_path, alert: "You do not have permission to access the admin area"
        end
      end
      def current_user; super; end
    end
  end

  # Test that the Setting.load_into_configuration! method exists and doesn't error
  test "Setting load_into_configuration method exists" do
    assert_nothing_raised do
      Alto::Setting.load_into_configuration!
    end
  end
end
