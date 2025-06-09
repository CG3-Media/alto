class RemoveEmailNotificationSettings < ActiveRecord::Migration[7.2]
  def up
    # Remove email notification settings from the database
    # These are no longer used since notifications are handled via callbacks

    email_setting_keys = [
      'notifications_enabled',
      'notification_from_email',
      'admin_notification_emails',
      'notify_ticket_author',
      'notify_admins_of_new_tickets',
      'notify_admins_of_new_comments'
    ]

    if table_exists?(:feedback_board_settings)
      email_setting_keys.each do |key|
        execute "DELETE FROM feedback_board_settings WHERE key = '#{key}'"
      end

      puts "✅ Removed #{email_setting_keys.length} email notification settings from database"
      puts "📧 Email notifications are now handled via callback system in your host app"
    end
  end

  def down
    # This migration is not reversible as we don't want to restore old email settings
    raise ActiveRecord::IrreversibleMigration,
          "Email notification settings removal cannot be reversed. " \
          "Use callback system for notifications instead."
  end
end
