module Alto
  class Engine < ::Rails::Engine
    isolate_namespace Alto

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Ensure configuration is available early
    initializer "alto.configuration", before: "active_record.initialize_database" do
      # Initialize configuration early to avoid namespace issues
      ::Alto.configure { }
    end

    # Auto-setup database schema when engine loads (disabled - use install generator instead)
    # initializer "alto.setup_database", after: "active_record.initialize_database" do
    #   ActiveSupport.on_load(:active_record) do
    #     ::Alto::DatabaseSetup.setup_if_needed
    #   end
    # end

    # Configure importmaps for nobuild JavaScript
    initializer "alto.importmap", before: "importmap" do |app|
      # Add our JavaScript files to the importmap
      if defined?(Importmap)
        app.config.importmap.draw do
          pin "alto", to: "alto/application.js"
        end
      end
    end

    # Configure assets to be served directly (nobuild)
    initializer "alto.assets" do |app|
      # Add our asset paths so they can be served directly
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.paths << root.join("app", "assets", "stylesheets")

      # Precompile our assets for production (but serve directly in development)
      app.config.assets.precompile += %w[
        alto/application.css

        alto/application.js
        alto/reactive_rails_form.js
        alto/multi_select.js
        alto/image_upload.js
      ]
    end

    # Load persistent settings from database after Rails initialization
    initializer "alto.load_settings", after: "active_record.initialize_database" do |app|
      app.config.after_initialize do
        # Load settings from database into configuration
        # Use ActiveSupport::Reloader to handle development reloading
        ActiveSupport::Reloader.to_prepare do
          begin
            ::Alto::Setting.load_into_configuration! if ::Alto::Setting.table_exists?
          rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
            # Database might not be ready yet (migrations pending, etc.)
            Rails.logger.debug "Alto: Database not ready, using default configuration"
          end
        end
      end
    end
  end
end
