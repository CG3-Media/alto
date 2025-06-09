module FeedbackBoard
  class Board < ApplicationRecord
    has_many :tickets, dependent: :restrict_with_error
    belongs_to :status_set, optional: true

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
    validates :slug, format: { with: /\A[a-z0-9\-_]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and underscores" }

    before_validation :generate_slug, if: :name_changed?

    scope :by_slug, ->(slug) { where(slug: slug) }
    scope :ordered, -> { order(:name) }

    def to_param
      slug
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
      tickets_count == 0 || FeedbackBoard.configuration.allow_board_deletion_with_tickets
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

    private

    def generate_slug
      return unless name.present?

      # Generate URL-friendly slug from name
      base_slug = name.downcase
                     .gsub(/[^a-z0-9\s\-_]/, '') # Remove special characters except spaces, hyphens, underscores
                     .gsub(/\s+/, '-')           # Replace spaces with hyphens
                     .gsub(/-+/, '-')            # Replace multiple hyphens with single hyphen
                     .gsub(/\A-+|-+\z/, '')     # Remove leading/trailing hyphens

      # Ensure uniqueness
      counter = 0
      potential_slug = base_slug

      while self.class.exists?(slug: potential_slug) && (new_record? || potential_slug != slug_was)
        counter += 1
        potential_slug = "#{base_slug}-#{counter}"
      end

      self.slug = potential_slug
    end
  end
end
