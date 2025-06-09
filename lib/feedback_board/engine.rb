module FeedbackBoard
  class Engine < ::Rails::Engine
    isolate_namespace FeedbackBoard

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Ensure configuration is available early
    initializer "feedback_board.configuration", before: "active_record.initialize_database" do
      # Initialize configuration early to avoid namespace issues
      ::FeedbackBoard.configure {}
    end

    # Auto-setup database schema when engine loads (disabled - use install generator instead)
    # initializer "feedback_board.setup_database", after: "active_record.initialize_database" do
    #   ActiveSupport.on_load(:active_record) do
    #     ::FeedbackBoard::DatabaseSetup.setup_if_needed
    #   end
    # end

    # Configure importmaps for nobuild JavaScript
    initializer "feedback_board.importmap", before: "importmap" do |app|
      # Add our JavaScript files to the importmap
      if defined?(Importmap)
        app.config.importmap.draw do
          pin "feedback_board", to: "feedback_board/application.js"
        end
      end
    end

    # Configure assets to be served directly (nobuild)
    initializer "feedback_board.assets" do |app|
      # Add our asset paths so they can be served directly
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.paths << root.join("app", "assets", "stylesheets")

      # Precompile our assets for production (but serve directly in development)
      app.config.assets.precompile += %w[
        feedback_board/application.js
        feedback_board/application.css
      ]
    end

    # Load persistent settings from database after Rails initialization
    initializer "feedback_board.load_settings", after: "active_record.initialize_database" do |app|
      app.config.after_initialize do
        # Load settings from database into configuration
        # Use ActiveSupport::Reloader to handle development reloading
        ActiveSupport::Reloader.to_prepare do
          begin
            ::FeedbackBoard::Setting.load_into_configuration! if ::FeedbackBoard::Setting.table_exists?
          rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
            # Database might not be ready yet (migrations pending, etc.)
            Rails.logger.debug "FeedbackBoard: Database not ready, using default configuration"
          end
        end
      end
    end
  end
end
