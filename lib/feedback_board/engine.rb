module FeedbackBoard
  class Engine < ::Rails::Engine
    isolate_namespace FeedbackBoard

        # Only add JS paths if not using Vite
    unless defined?(ViteRuby)
      config.autoload_paths += %W(#{config.root}/app/assets/javascripts)

      initializer "feedback_board.assets" do |app|
        app.config.assets.paths << root.join("app", "assets", "javascripts")
      end
    end

    initializer "feedback_board.stimulus" do |app|
      if defined?(Stimulus)
        # Auto-register our Stimulus controllers with the host app
        app.config.after_initialize do
          # The host app can manually import our controllers if needed
          # import UpvoteController from "feedback_board/controllers/upvote_controller"
          # application.register("upvote", UpvoteController)
        end
      end
    end

    # Load persistent settings from database after Rails initialization
    initializer "feedback_board.load_settings", after: "active_record.initialize_database" do |app|
      app.config.after_initialize do
        # Load settings from database into configuration
        # Use ActiveSupport::Reloader to handle development reloading
        ActiveSupport::Reloader.to_prepare do
          begin
            FeedbackBoard::Setting.load_into_configuration! if FeedbackBoard::Setting.table_exists?
          rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
            # Database might not be ready yet (migrations pending, etc.)
            Rails.logger.debug "FeedbackBoard: Database not ready, using default configuration"
          end
        end
      end
    end
  end
end
