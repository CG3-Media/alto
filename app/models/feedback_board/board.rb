module FeedbackBoard
  class Board < ApplicationRecord
    include Sluggable

    has_many :tickets, dependent: :restrict_with_error
    belongs_to :status_set, optional: true

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, uniqueness: true

    scope :ordered, -> { order(:name) }

    def slug_source_attribute
      :name
    end

    def tickets_count
      tickets.count
    end

    def recent_tickets(limit = 5)
      tickets.recent.limit(limit)
    end

    def popular_tickets(limit = 5)
      tickets.popular.limit(limit)
    end

    # Search tickets within this board
    def search_tickets(query)
      tickets.search(query)
    end

    # Check if board can be safely deleted (no tickets)
    def can_be_deleted?
      tickets_count == 0 || ::FeedbackBoard.configuration.allow_board_deletion_with_tickets
    end

    # Status-related methods
    def has_status_tracking?
      status_set.present? && status_set.has_statuses?
    end

    def available_statuses
      return [] unless has_status_tracking?
      status_set.statuses.ordered
    end

    def status_options_for_select
      return [] unless has_status_tracking?
      status_set.status_options_for_select
    end

    def default_status_slug
      return nil unless has_status_tracking?
      status_set.first_status&.slug
    end

    def status_by_slug(slug)
      return nil unless has_status_tracking?
      status_set.status_by_slug(slug)
    end

  end
end
