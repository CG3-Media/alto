module FeedbackBoard
  class Configuration
    attr_accessor :user_model, :default_board_name, :default_board_slug,
                  :allow_board_deletion_with_tickets

    # Permission method blocks - much cleaner than delegation!
    attr_accessor :permission_methods

    def initialize
      # Default configuration: try common name fields, fallback to email
      @user_display_name_block = default_user_display_name_block
      @user_model = "User"

      # App branding default (fallback if database not available)
      @default_app_name = "Feedback Board"

      # Board configuration defaults
      @default_board_name = "Feedback"
      @default_board_slug = "feedback"
      @allow_board_deletion_with_tickets = false

      # Initialize permission methods hash
      @permission_methods = {}
    end

    # Define permission methods with blocks or procs
    def permission(method_name, proc_or_block = nil, &block)
      @permission_methods[method_name.to_sym] = proc_or_block || block
    end

    # Check if a permission method is defined
    def has_permission?(method_name)
      @permission_methods.key?(method_name.to_sym)
    end

    # Set user display name method with a block (matches README documentation)
    def user_display_name(&block)
      @user_display_name_block = block if block_given?
      @user_display_name_block
    end

            # Call a permission method block or proc
    def call_permission(method_name, controller_context, *args)
      block_or_proc = @permission_methods[method_name.to_sym]
      return nil unless block_or_proc

      # Call the block/proc in the context of the controller
      controller_context.instance_exec(*args, &block_or_proc)
    end

    # Database-backed app_name with fallback to default
    def app_name
      return @default_app_name unless database_available?
      ::FeedbackBoard::Setting.get('app_name', @default_app_name)
    end

    def app_name=(value)
      if database_available?
        ::FeedbackBoard::Setting.set('app_name', value)
      else
        # During setup/migrations, just store in memory
        @default_app_name = value
      end
    end

    private

    def database_available?
      return false unless defined?(::FeedbackBoard::Setting)
      ::FeedbackBoard::Setting.table_exists?
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      false
    end

    def default_user_display_name_block
      proc do |user_id|
        return "Anonymous" unless user_id

        # Get the user model class (configurable, defaults to User)
        user_class = user_model.constantize rescue nil
        return "Anonymous" unless user_class

        user = user_class.find_by(id: user_id)
        return "Anonymous" unless user

        # Try different name fields in order of preference
        if user.respond_to?(:full_name) && user.full_name.present?
          user.full_name
        elsif user.respond_to?(:first_name) && user.respond_to?(:last_name) &&
              (user.first_name.present? || user.last_name.present?)
          "#{user.first_name} #{user.last_name}".strip
        elsif user.respond_to?(:first_name) && user.first_name.present?
          user.first_name
        elsif user.respond_to?(:last_name) && user.last_name.present?
          user.last_name
        elsif user.respond_to?(:email) && user.email.present?
          user.email
        else
          "User ##{user_id}"
        end
      end
    end
  end
end
