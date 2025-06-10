module Alto
  class Board < ApplicationRecord
    include Sluggable

    has_many :tickets, dependent: :restrict_with_error
    belongs_to :status_set

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, uniqueness: true
    validates :item_label_singular, presence: true, length: { maximum: 50 },
              format: { with: /\A[a-z ]+\z/i, message: 'only letters and spaces allowed' }
    validates :status_set, presence: true

    scope :ordered, -> { order(:name) }
    scope :public_boards, -> { where(is_admin_only: false) }
    scope :admin_only_boards, -> { where(is_admin_only: true) }

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
      tickets_count == 0 || ::Alto.configuration.allow_board_deletion_with_tickets
    end

    # Status-related methods
    def has_status_tracking?
      status_set&.has_statuses? || false
    end

    def available_statuses
      return [] unless status_set
      status_set.statuses.ordered
    end

    def status_options_for_select
      return [] unless status_set
      status_set.status_options_for_select
    end

    def default_status_slug
      return nil unless status_set
      status_set.first_status&.slug
    end

    def status_by_slug(slug)
      return nil unless status_set
      status_set.status_by_slug(slug)
    end

    # Item labeling method
    def item_name
      item_label_singular.presence || 'ticket'
    end

    # Admin-only access methods
    def admin_only?
      is_admin_only?
    end

    def publicly_accessible?
      !is_admin_only?
    end

    # Scope boards based on user's admin status
    def self.accessible_to_user(user, current_user_is_admin: false)
      if current_user_is_admin
        all
      else
        public_boards
      end
    end

  end
end
