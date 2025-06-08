module FeedbackBoard
  class Upvote < ApplicationRecord
    belongs_to :upvotable, polymorphic: true

    validates :user_id, presence: true
    validates :user_id, uniqueness: { scope: [:upvotable_type, :upvotable_id] }

    scope :for_tickets, -> { where(upvotable_type: 'FeedbackBoard::Ticket') }
    scope :for_comments, -> { where(upvotable_type: 'FeedbackBoard::Comment') }
  end
end
