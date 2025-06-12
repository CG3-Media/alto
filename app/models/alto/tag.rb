module Alto
  class Tag < ApplicationRecord
    include Sluggable

    belongs_to :board
    has_many :taggings, dependent: :destroy
    has_many :tickets, through: :taggings, source: :taggable, source_type: "Alto::Ticket"

    validates :name, presence: true, 
                     length: { maximum: 50 },
                     format: { with: /\A[a-zA-Z0-9\-_\.]+\z/, message: "only letters, numbers, hyphens, underscores, and dots allowed" },
                     uniqueness: { scope: :board_id }

    validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color (e.g., #ff0000)" }, 
                      allow_blank: true

    validates :board, presence: true
    validates :usage_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

    before_validation :normalize_name
    before_validation :set_default_usage_count

    scope :ordered, -> { order(:name) }
    scope :for_board, ->(board) { where(board: board) }
    scope :popular, -> { order(usage_count: :desc) }
    scope :used, -> { where("usage_count > 0") }
    scope :unused, -> { where(usage_count: 0) }

    def slug_source_attribute
      :name
    end

    def color_classes
      if color.present?
        # Convert hex color to Tailwind-style classes
        # This is a simple implementation - in a real app you might want a more sophisticated approach
        case color.downcase
        when "#ff0000", "#dc2626", "#ef4444" then "bg-red-100 text-red-800"
        when "#00ff00", "#16a34a", "#22c55e" then "bg-green-100 text-green-800"
        when "#0000ff", "#2563eb", "#3b82f6" then "bg-blue-100 text-blue-800"
        when "#ffff00", "#ca8a04", "#eab308" then "bg-yellow-100 text-yellow-800"
        when "#ff8c00", "#ea580c", "#f97316" then "bg-orange-100 text-orange-800"
        when "#800080", "#9333ea", "#a855f7" then "bg-purple-100 text-purple-800"
        when "#ffc0cb", "#ec4899", "#f472b6" then "bg-pink-100 text-pink-800"
        else "bg-gray-100 text-gray-800"
        end
      else
        "bg-gray-100 text-gray-800"
      end
    end

    def increment_usage!
      increment!(:usage_count)
    end

    def decrement_usage!
      decrement!(:usage_count) if usage_count > 0
    end

    def used?
      usage_count > 0
    end

    def can_be_deleted?
      !used? || ::Alto.configuration.allow_tag_deletion_with_usage
    end

    private

    def normalize_name
      if name.present?
        self.name = name.strip.downcase
      end
    end

    def set_default_usage_count
      self.usage_count ||= 0
    end
  end
end