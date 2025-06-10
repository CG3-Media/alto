module Alto
  class Subscription < ApplicationRecord
    belongs_to :ticket

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :ticket_id, presence: true
    validates :email, uniqueness: { scope: :ticket_id, message: "is already subscribed to this ticket" }

    scope :active, -> { where.not(email: nil) }
  end
end
