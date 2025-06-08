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

        # Search scopes
    scope :search_by_content, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"
      # Use ILIKE for PostgreSQL, LIKE for others (case-insensitive search)
      if connection.adapter_name.downcase.include?('postgresql')
        where("title ILIKE ? OR description ILIKE ?", sanitized_query, sanitized_query)
      else
        where("LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", sanitized_query, sanitized_query)
      end
    }

    scope :search_by_comments, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"
      if connection.adapter_name.downcase.include?('postgresql')
        joins(:comments).where("feedback_board_comments.content ILIKE ?", sanitized_query)
      else
        joins(:comments).where("LOWER(feedback_board_comments.content) LIKE LOWER(?)", sanitized_query)
      end
    }

        scope :search, ->(query) {
      return all if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query.strip)}%"

      # Combined search in tickets OR comments with a single query
      if connection.adapter_name.downcase.include?('postgresql')
        left_joins(:comments).where(
          "(feedback_board_tickets.title ILIKE ? OR feedback_board_tickets.description ILIKE ?) OR feedback_board_comments.content ILIKE ?",
          sanitized_query, sanitized_query, sanitized_query
        ).distinct
      else
        left_joins(:comments).where(
          "(LOWER(feedback_board_tickets.title) LIKE LOWER(?) OR LOWER(feedback_board_tickets.description) LIKE LOWER(?)) OR LOWER(feedback_board_comments.content) LIKE LOWER(?)",
          sanitized_query, sanitized_query, sanitized_query
        ).distinct
      end
    }

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
