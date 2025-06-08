module FeedbackBoard
  class Ticket < ApplicationRecord
    STATUSES = %w[open planned in_progress complete].freeze

    has_many :comments, dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :user_id, presence: true

    scope :by_status, ->(status) { where(status: status) }
    scope :unlocked, -> { where(locked: false) }
    scope :locked, -> { where(locked: true) }
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
      !locked?
    end

    def can_be_commented_on?
      !locked?
    end
  end
end
