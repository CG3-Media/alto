module FeedbackBoard
  class Status < ApplicationRecord
    belongs_to :status_set

    validates :name, presence: true, length: { maximum: 50 }
    validates :slug, presence: true, length: { maximum: 50 }
    validates :color, presence: true, inclusion: { in: %w[green blue yellow red gray purple orange pink] }
    validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :slug, uniqueness: { scope: :status_set_id }

    scope :ordered, -> { order(:position) }

    def color_classes
      case color
      when 'green'
        'bg-green-100 text-green-800'
      when 'blue'
        'bg-blue-100 text-blue-800'
      when 'yellow'
        'bg-yellow-100 text-yellow-800'
      when 'red'
        'bg-red-100 text-red-800'
      when 'gray'
        'bg-gray-100 text-gray-800'
      when 'purple'
        'bg-purple-100 text-purple-800'
      when 'orange'
        'bg-orange-100 text-orange-800'
      when 'pink'
        'bg-pink-100 text-pink-800'
      else
        'bg-gray-100 text-gray-800'
      end
    end

    def to_param
      slug
    end
  end
end
