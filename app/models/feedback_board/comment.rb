module FeedbackBoard
  class Comment < ApplicationRecord
    belongs_to :ticket
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :content, presence: true
    validates :user_id, presence: true

    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order('count(feedback_board_upvotes.id) desc') }

    def upvoted_by?(user)
      return false unless user
      upvotes.exists?(user_id: user.id)
    end

    def upvotes_count
      upvotes.count
    end

    def can_be_voted_on?
      !ticket.locked?
    end
  end
end
