module FeedbackBoard
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install FeedbackBoard engine with Stimulus controllers"

      def create_stimulus_setup
        say "Setting up FeedbackBoard Stimulus controllers...", :green

        create_file "app/javascript/controllers/feedback_board_controller.js", <<~JS
          // FeedbackBoard Stimulus Controllers
          // Copy the upvote_controller.js from the engine and register it:

          // import { application } from "./application"
          // import UpvoteController from "feedback_board/controllers/upvote_controller"
          // application.register("upvote", UpvoteController)
        JS
      end

      def show_setup_instructions
        say "\n" + "="*60, :green
        say "🎉 FeedbackBoard Installation Complete!", :green
        say "="*60, :green

        say "\nNext steps:", :yellow
        say "1. Add to your routes.rb:", :cyan
        say "   mount FeedbackBoard::Engine => '/feedback'"

        say "\n2. Run migrations:", :cyan
        say "   rails feedback_board:install:migrations"
        say "   rails db:migrate"

                say "\n3. Copy the Stimulus controller:", :cyan
        say "   cp $(bundle show feedback_board)/app/assets/javascripts/feedback_board/controllers/upvote_controller.js app/javascript/controllers/"

        say "\n4. Register the Stimulus controller in app/javascript/controllers/index.js:", :cyan
        say '   import UpvoteController from "./upvote_controller"'
        say '   application.register("upvote", UpvoteController)'

        say "\n💡 Alternative: If you prefer not to copy files, you can:", :blue
        say "   - Install the engine dependencies: bundle install"
        say "   - The upvote buttons will still work, just without AJAX (they'll do page refreshes)"

        say "\n5. Make sure your layout includes:", :cyan
        say "   <%= csrf_meta_tags %>"
        say "   <%= javascript_importmap_tags %> (if using importmap)"

        say "\n📚 Check the README for permission setup and customization options!", :blue
      end
    end
  end
end
