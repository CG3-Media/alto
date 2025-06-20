module Alto
  class Upvote < ApplicationRecord
    include ::Alto::Subscribable

    belongs_to :upvotable, polymorphic: true
    belongs_to :user, polymorphic: true

    validates :user_id, presence: true
    validates :user_id, uniqueness: { scope: [ :upvotable_type, :upvotable_id ] }

    # Set user_type for polymorphic association
    before_validation :set_user_type, if: -> { user_id.present? && user_type.blank? }

    # Host app callback hooks
    after_create :trigger_upvote_created_callback
    after_destroy :trigger_upvote_removed_callback

    scope :for_tickets, -> { where(upvotable_type: "Alto::Ticket") }
    scope :for_comments, -> { where(upvotable_type: "Alto::Comment") }

    # Subscribable concern implementation
    def subscribable_ticket
      if upvotable.respond_to?(:board)
        # Upvoting a ticket directly
        upvotable
      elsif upvotable.respond_to?(:ticket)
        # Upvoting a comment - subscribe to the comment's ticket
        upvotable.ticket
      else
        nil
      end
    end

    def user_email
      ::Alto.configuration.user_email.call(user_id)
    end

    private

    def trigger_upvote_created_callback
      board = upvotable.respond_to?(:board) ? upvotable.board : upvotable.ticket&.board
      ::Alto::CallbackManager.call(:upvote_created, self, upvotable, board, get_user_object(user_id))
    end

    def trigger_upvote_removed_callback
      board = upvotable.respond_to?(:board) ? upvotable.board : upvotable.ticket&.board
      ::Alto::CallbackManager.call(:upvote_removed, self, upvotable, board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      user_class = ::Alto.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user_class.find_by(id: user_id)
    end

    def set_user_type
      self.user_type = ::Alto.configuration.user_model if user_id.present?
    end
  end
end
