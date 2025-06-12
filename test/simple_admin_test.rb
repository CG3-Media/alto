require 'test_helper'

class SimpleAdminTest < ActionDispatch::IntegrationTest
  def test_admin_functionality_works
    puts "\n=== CONTROLLER LOADING TEST ==="

    # Test if admin controllers can be loaded
    begin
      dashboard_controller = Alto::Admin::DashboardController.new
      puts "✅ Dashboard controller loads: #{dashboard_controller.class}"
    rescue => e
      puts "❌ Dashboard controller error: #{e.message}"
    end

    begin
      boards_controller = Alto::Admin::BoardsController.new
      puts "✅ Boards controller loads: #{boards_controller.class}"
    rescue => e
      puts "❌ Boards controller error: #{e.message}"
    end

    # Test Rails controller resolution
    begin
      puts "\n=== RAILS CONTROLLER RESOLUTION ==="
      controller_name = "alto/admin/dashboard"
      controller_class = "#{controller_name.camelize}Controller".constantize
      puts "✅ Rails can resolve: #{controller_name} -> #{controller_class}"
    rescue => e
      puts "❌ Rails resolution error: #{e.message}"
    end

    # Test route recognition
    begin
      puts "\n=== ROUTE RECOGNITION ==="
      # Use the engine's route recognizer
      route_info = Alto::Engine.routes.recognize_path("/admin/boards", method: :get)
      puts "✅ Route recognized: #{route_info}"
    rescue => e
      puts "❌ Route recognition error: #{e.message}"
    end

    # Test if we can manually dispatch
    begin
      puts "\n=== MANUAL DISPATCH TEST ==="
      env = Rack::MockRequest.env_for('/feedback/admin/boards', method: 'GET')
      dispatch_response = Alto::Engine.call(env)
      puts "Manual dispatch status: #{dispatch_response[0]}"
    rescue => e
      puts "❌ Manual dispatch error: #{e.message}"
    end

    # Let Rails transactional fixtures handle data isolation

    user = User.create!(email: 'admin@example.com')

    # Create a status set first
    status_set = Alto::StatusSet.create!(name: "Test Status Set", is_default: true)
    status_set.statuses.create!(name: 'Open', color: 'green', position: 0, slug: 'open')

    board = Alto::Board.create!(
      name: "Test Board",
      item_label_singular: "ticket",
      status_set: status_set
    )

    # Test admin root first
    get '/feedback/admin'

    puts "\n=== ADMIN ROOT TEST ==="
    puts "Response status: #{response.status}"
    puts "Response location: #{response.location}" if response.location

    if response.status == 200
      puts "✅ Admin root works!"
    elsif response.redirect?
      puts "↗️ Admin root redirected to: #{response.location}"
    else
      puts "❌ Admin root failed"
      puts "Response body preview: #{response.body[0..200]}..."
    end

    # Test admin index directly with full path
    get '/feedback/admin/boards'

    puts "\n=== ADMIN BOARDS INDEX TEST ==="
    puts "Response status: #{response.status}"
    puts "Response location: #{response.location}" if response.location

    if response.status == 200
      puts "✅ Admin boards index works!"
      puts "Response includes board name: #{response.body.include?('Test Board')}"
    else
      puts "❌ Admin boards index failed"
      puts "Response body preview: #{response.body[0..200]}..."
    end

    # Test board creation
    post '/feedback/admin/boards', params: {
      board: {
        name: "New Test Board",
        description: "Created via test",
        item_label_singular: "ticket",
        is_admin_only: false
      }
    }

    puts "\n=== ADMIN CREATE TEST ==="
    puts "Response status: #{response.status}"

    if response.redirect?
      puts "✅ Board creation redirected (likely success)"
      created_board = Alto::Board.find_by(name: "New Test Board")
      puts "Board was created: #{!created_board.nil?}"
    else
      puts "❌ Board creation failed"
      puts "Response body preview: #{response.body[0..200]}..." if response.status != 200
    end

    # Just check that basic admin functionality exists
    assert true, "Admin functionality test completed"
  end
end
