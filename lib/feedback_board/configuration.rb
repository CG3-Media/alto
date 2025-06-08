module FeedbackBoard
  class Configuration
    attr_accessor :user_display_name_method, :user_model

    def initialize
      # Default configuration: try common name fields, fallback to email
      @user_display_name_method = default_user_display_name_method
      @user_model = "User"
    end

    private

    def default_user_display_name_method
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
