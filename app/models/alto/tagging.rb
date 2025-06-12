module Alto
  class Tagging < ApplicationRecord
    belongs_to :tag
    belongs_to :taggable, polymorphic: true

    validates :tag, presence: true
    validates :taggable, presence: true
    validates :tag_id, uniqueness: { scope: [:taggable_type, :taggable_id] }

    validate :tag_and_taggable_same_board

    after_create :increment_tag_usage
    after_destroy :decrement_tag_usage

    scope :for_tag, ->(tag) { where(tag: tag) }
    scope :for_taggable_type, ->(type) { where(taggable_type: type) }

    def board
      tag.board
    end

    private

    def tag_and_taggable_same_board
      return unless tag.present? && taggable.present?

      if taggable.respond_to?(:board) && taggable.board != tag.board
        errors.add(:tag, "must belong to the same board as the tagged item")
      end
    end

    def increment_tag_usage
      tag.increment_usage! if tag.present?
    end

    def decrement_tag_usage
      tag.decrement_usage! if tag.present?
    end
  end
end