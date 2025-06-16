module Alto
  module Sluggable
    extend ActiveSupport::Concern

    included do
      validates :slug, presence: true, length: { maximum: 100 }
      validates :slug, format: { with: /\A[a-z0-9\-_]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and underscores" }, if: :slug_present?

      before_validation :generate_slug, if: :should_generate_slug?

      scope :by_slug, ->(slug) { where(slug: slug) }
    end

    class_methods do
      # Smart finder that works with both slug and ID
      # Tries slug first (most common case), falls back to ID if needed
      def find_by_slug_or_id(param)
        return nil if param.blank?

        # Try finding by slug first (most common case)
        record = find_by(slug: param)

        # If not found by slug and param looks like an ID, try finding by ID
        if record.nil? && param.to_s.match?(/\A\d+\z/)
          record = find_by(id: param)
        end

        record
      end

      # Enhanced finder with exception (like find!)
      def find_by_slug_or_id!(param)
        record = find_by_slug_or_id(param)
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with slug or id=#{param}" if record.nil?
        record
      end

      # Override find to transparently handle both slug and ID
      def find(param)
        return super if param.blank?

        # Use our smart finder logic
        record = find_by_slug_or_id(param)

        # If still not found, raise the standard ActiveRecord exception
        if record.nil?
          raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with slug or id=#{param}"
        end

        record
      end

      # For scoped lookups (like Status with status_set_id)
      def find_by_slug_or_id_in_scope!(param, scope_conditions = {})
        return nil if param.blank?

        scope = where(scope_conditions)

        # Try finding by slug first
        record = scope.find_by(slug: param)

        # If not found by slug and param looks like an ID, try finding by ID
        if record.nil? && param.to_s.match?(/\A\d+\z/)
          record = scope.find_by(id: param)
        end

        if record.nil?
          scope_desc = scope_conditions.map { |k, v| "#{k}=#{v}" }.join(", ")
          raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with slug or id=#{param} in scope: #{scope_desc}"
        end

        record
      end
    end

    def to_param
      slug
    end

    # Helper to check if this record can be found by the given param
    def matches_param?(param)
      slug == param.to_s || id.to_s == param.to_s
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
                            .gsub(/[^a-z0-9\s\-_]/, "") # Remove special characters except spaces, hyphens, underscores
                            .gsub(/\s+/, "-")           # Replace spaces with hyphens
                            .gsub(/-+/, "-")            # Replace multiple hyphens with single hyphen
                            .gsub(/\A-+|-+\z/, "")     # Remove leading/trailing hyphens

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
