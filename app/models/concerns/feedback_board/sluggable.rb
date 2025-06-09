module FeedbackBoard
  module Sluggable
    extend ActiveSupport::Concern

    included do
      validates :slug, presence: true, length: { maximum: 100 }
      validates :slug, format: { with: /\A[a-z0-9\-_]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and underscores" }, if: :slug_present?

      before_validation :generate_slug, if: :should_generate_slug?

      scope :by_slug, ->(slug) { where(slug: slug) }
    end

    def to_param
      slug
    end

    private

    def slug_present?
      slug.present?
    end

    def should_generate_slug?
      # Generate slug if it's blank or if the source attribute changed
      slug.blank? || (respond_to?(:slug_source_attribute) && slug_source_attribute_changed?)
    end

    def slug_source_attribute_changed?
      return false unless respond_to?(:slug_source_attribute)
      public_send("#{slug_source_attribute}_changed?")
    end

        def generate_slug
      return unless respond_to?(:slug_source_attribute)
      return unless public_send(slug_source_attribute).present?

      source_text = public_send(slug_source_attribute)

      # Generate URL-friendly slug from source attribute
      base_slug = source_text.downcase
                            .gsub(/[^a-z0-9\s\-_]/, '') # Remove special characters except spaces, hyphens, underscores
                            .gsub(/\s+/, '-')           # Replace spaces with hyphens
                            .gsub(/-+/, '-')            # Replace multiple hyphens with single hyphen
                            .gsub(/\A-+|-+\z/, '')     # Remove leading/trailing hyphens

      # Handle edge case where slug becomes empty after cleaning
      if base_slug.blank?
        base_slug = "item"
      end

      # Ensure uniqueness within the appropriate scope
      counter = 0
      potential_slug = base_slug

      while slug_exists?(potential_slug) && (new_record? || potential_slug != slug_was)
        counter += 1
        potential_slug = "#{base_slug}-#{counter}"
      end

      self.slug = potential_slug
    end

    def slug_exists?(potential_slug)
      scope = self.class.where(slug: potential_slug)

      # If model has a uniqueness scope (like Status with status_set_id), apply it
      if respond_to?(:slug_uniqueness_scope)
        slug_uniqueness_scope.each do |scope_attribute|
          scope = scope.where(scope_attribute => public_send(scope_attribute))
        end
      end

      scope.exists?
    end
  end
end
