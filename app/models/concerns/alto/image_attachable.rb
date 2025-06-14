module Alto
  module ImageAttachable
    extend ActiveSupport::Concern

    included do
      # Only add image attachments if enabled and ActiveStorage is available
      if ::Alto.configuration.image_uploads_enabled && defined?(ActiveStorage)
        has_many_attached :images

        # Optional validation to enforce one image per post
        validate :only_one_image_allowed, if: :enforce_single_image?

        # Validate image size (5MB max)
        validate :acceptable_image_size

        # Validate image type
        validate :acceptable_image_type
      end
    end

    private

    def only_one_image_allowed
      if images.attached? && images.size > 1
        errors.add(:images, "only one image is allowed")
      end
    end

    def acceptable_image_size
      return unless images.attached?

      images.each do |image|
        if image.byte_size > 5.megabytes
          errors.add(:images, "#{image.filename} is too large (maximum is 5MB)")
        end
      end
    end

    def acceptable_image_type
      return unless images.attached?

      acceptable_types = %w[image/jpeg image/png image/gif image/webp]

      images.each do |image|
        unless acceptable_types.include?(image.content_type)
          errors.add(:images, "#{image.filename} must be a JPEG, PNG, GIF, or WebP")
        end
      end
    end

    def enforce_single_image?
      # This can be overridden in the model if needed
      true
    end
  end
end
