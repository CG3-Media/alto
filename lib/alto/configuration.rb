module Alto
  class Configuration
    attr_accessor :user_model, :default_board_name, :default_board_slug,
                  :allow_board_deletion_with_tickets, :current_user_proc

    # Permission method blocks - much cleaner than delegation!
    attr_accessor :permission_methods

    def initialize
      # Default configuration: try common name fields, fallback to email
      @user_display_name_block = default_user_display_name_block
      @user_email_block = default_user_email_block
      @user_profile_avatar_url_block = default_user_profile_avatar_url_block
      @user_model = "User"

      # App branding default (fallback if database not available)
      @default_app_name = "Alto"

      # Board configuration defaults
      @default_board_name = "Feedback"
      @default_board_slug = "feedback"
      @allow_board_deletion_with_tickets = false

      # Initialize permission methods hash
      @permission_methods = {}

      # Default current_user proc - tries common authentication patterns safely
      @current_user_proc = proc do
        # Try standard Rails current_user method first
        if respond_to?(:current_user)
          current_user
        # Try Current.user pattern (thread-local storage)
        elsif defined?(Current) && Current.respond_to?(:user)
          Current.user
        else
          # Safe fallback - no user
          nil
        end
      end
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

    # Set user email method with a block
    def user_email(&block)
      @user_email_block = block if block_given?
      @user_email_block
    end

    # Set user profile avatar URL method with a block
    def user_profile_avatar_url(&block)
      @user_profile_avatar_url_block = block if block_given?
      @user_profile_avatar_url_block
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
      ::Alto::Setting.get("app_name", @default_app_name)
    end

    def app_name=(value)
      if database_available?
        ::Alto::Setting.set("app_name", value)
      else
        # During setup/migrations, just store in memory
        @default_app_name = value
      end
    end

    # Set current_user proc for authentication integration
    def current_user(&block)
      @current_user_proc = block if block_given?
      @current_user_proc
    end

    private

    def database_available?
      return false unless defined?(::Alto::Setting)
      ::Alto::Setting.table_exists?
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

    def default_user_email_block
      proc do |user_id|
        return nil unless user_id

        # Get the user model class (configurable, defaults to User)
        user_class = user_model.constantize rescue nil
        return nil unless user_class

        user = user_class.find_by(id: user_id)
        return nil unless user

        # Try common email field names
        if user.respond_to?(:email) && user.email.present?
          user.email
        elsif user.respond_to?(:email_address) && user.email_address.present?
          user.email_address
        else
          nil
        end
      end
    end

    def default_user_profile_avatar_url_block
      proc do |user_id|
        # Default: no avatar URL - host app must configure this
        nil
      end
    end
  end
end
