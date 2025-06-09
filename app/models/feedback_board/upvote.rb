module FeedbackBoard
  class Upvote < ApplicationRecord
    belongs_to :upvotable, polymorphic: true

    validates :user_id, presence: true
    validates :user_id, uniqueness: { scope: [:upvotable_type, :upvotable_id] }

    # Host app callback hooks
    after_create :trigger_upvote_created_callback
    after_destroy :trigger_upvote_removed_callback

    scope :for_tickets, -> { where(upvotable_type: 'FeedbackBoard::Ticket') }
    scope :for_comments, -> { where(upvotable_type: 'FeedbackBoard::Comment') }

    private

    def trigger_upvote_created_callback
      board = upvotable.respond_to?(:board) ? upvotable.board : upvotable.ticket&.board
      ::FeedbackBoard::CallbackManager.call(:upvote_created, self, upvotable, board, get_user_object(user_id))
    end

    def trigger_upvote_removed_callback
      board = upvotable.respond_to?(:board) ? upvotable.board : upvotable.ticket&.board
      ::FeedbackBoard::CallbackManager.call(:upvote_removed, self, upvotable, board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      user_class = ::FeedbackBoard.configuration.user_model.constantize rescue nil
      return nil unless user_class

      user_class.find_by(id: user_id)
    end
  end
end
