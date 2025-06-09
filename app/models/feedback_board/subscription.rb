module FeedbackBoard
  class Subscription < ApplicationRecord
    belongs_to :ticket

    validates :email, presence: true
    validates :ticket_id, presence: true

    scope :active, -> { where.not(email: nil) }
  end
end
