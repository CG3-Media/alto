module Alto
  module UserHelper
    def user_display_name(user_id)
      ::Alto.config.user_display_name.call(user_id)
    end

    def user_profile_avatar_url(user_id)
      ::Alto.config.user_profile_avatar_url.call(user_id)
    end

    def has_user_avatar?(user_id)
      user_profile_avatar_url(user_id).present?
    end

      def app_name
    ::Alto.config.app_name
  end
  end
end
