module FeedbackBoard
  class NotificationMailer < ApplicationMailer
    def new_ticket(ticket, recipient_email)
      @ticket = ticket
      @user_name = user_display_name(@ticket.user_id)

      mail(
        to: recipient_email,
        subject: "[Feedback] New ticket: #{@ticket.title}",
        from: FeedbackBoard.configuration.notification_from_email
      )
    end

    def new_comment(comment, recipient_email)
      @comment = comment
      @ticket = comment.ticket
      @user_name = user_display_name(@comment.user_id)

      mail(
        to: recipient_email,
        subject: "[Feedback] New comment on: #{@ticket.title}",
        from: FeedbackBoard.configuration.notification_from_email
      )
    end

    def status_changed(ticket, recipient_email, old_status)
      @ticket = ticket
      @old_status = old_status
      @new_status = ticket.status

      mail(
        to: recipient_email,
        subject: "[Feedback] Status updated: #{@ticket.title}",
        from: FeedbackBoard.configuration.notification_from_email
      )
    end

    private

    def user_display_name(user_id)
      FeedbackBoard.configuration.user_display_name_method.call(user_id)
    end

    def app_name
      FeedbackBoard.configuration.app_name
    end
  end
end
