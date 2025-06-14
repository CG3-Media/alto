module Alto
  module ImageHelper
    # Default size configurations for different storage services
    DEFAULT_SIZES = {
      thumbnail: { width: 150, height: 150 },
      small: { width: 300, height: 300 },
      medium: { width: 600, height: 400 },
      large: { width: 1200, height: 800 }
    }.freeze

        # Checks if images should be displayed for a record
    # @param record [ActiveRecord::Base] The record with attached images
    # @return [Boolean] Whether images should be displayed
    def should_display_images?(record)
      image_uploads_enabled? && record_has_images?(record)
    end

    # Gets image data for display in views
    # @param image [ActiveStorage::Attachment, ActiveStorage::Blob] The attachment or blob object
    # @param size [Symbol, Hash] Size specification
    # @return [Hash] Image data with URLs and metadata
    def image_display_data(image, size: :medium)
      # Handle both ActiveStorage::Attachment and ActiveStorage::Blob
      blob = image.respond_to?(:blob) ? image.blob : image
      return nil unless blob.present?

      {
        image_url: generate_image_url(image, size),
        full_size_url: generate_image_url(image, :original),
        filename: blob.filename.to_s,
        file_size: blob.byte_size,
        size_class: size_to_css_class(size)
      }
    end

    private

    # Checks if image uploads are enabled in configuration
    def image_uploads_enabled?
      ::Alto.configuration.image_uploads_enabled
    end

    # Checks if record has images attached
    def record_has_images?(record)
      record.respond_to?(:images) && record.images.attached?
    end

        # Generates appropriate image URL based on host app's ActiveStorage configuration
    def generate_image_url(image, size)
      case detect_storage_service
      when :cloudinary
        generate_cloudinary_url(image, size)
      when :s3, :amazon
        generate_s3_url(image, size)
      else
        generate_rails_url(image, size)
      end
    end

    # Detects the current ActiveStorage service from host app configuration
    def detect_storage_service
      service_name = Rails.application.config.active_storage.service
      service_config = Rails.application.config.active_storage.service_configurations[service_name.to_s]

      return :cloudinary if service_config&.dig('service') == 'Cloudinary'
      return :s3 if service_config&.dig('service') == 'S3'
      return :amazon if service_config&.dig('service') == 'AmazonS3'

      :local
    end

    # Generates Cloudinary URL - let Cloudinary handle transformations
    def generate_cloudinary_url(image, size)
      # For Cloudinary, we don't use Rails variants - Cloudinary handles transformations
      # Just return the direct URL and let Cloudinary's auto-optimization handle sizing
      Rails.application.routes.url_helpers.url_for(image)
    rescue => e
      Rails.logger.warn "Alto::ImageHelper: Cloudinary URL generation failed: #{e.message}"
      Rails.application.routes.url_helpers.rails_blob_path(image, disposition: 'inline')
    end

    # Generates S3 URL with variant support
    def generate_s3_url(image, size)
      if size == :original || !image.variable?
        Rails.application.routes.url_helpers.url_for(image)
      else
        dimensions = size.is_a?(Hash) ? size : DEFAULT_SIZES[size]
        if dimensions
          Rails.application.routes.url_helpers.url_for(
            image.variant(resize_to_limit: [dimensions[:width], dimensions[:height]])
          )
        else
          Rails.application.routes.url_helpers.url_for(image)
        end
      end
    rescue => e
      Rails.logger.warn "Alto::ImageHelper: S3 URL generation failed: #{e.message}"
      Rails.application.routes.url_helpers.url_for(image)
    end

    # Generates standard Rails URL (for local storage or fallback)
    def generate_rails_url(image, size)
      if size == :original || !image.variable?
        url_for(image)
      else
        dimensions = size.is_a?(Hash) ? size : DEFAULT_SIZES[size]
        if dimensions
          url_for(image.variant(resize_to_limit: [dimensions[:width], dimensions[:height]]))
        else
          url_for(image)
        end
      end
    rescue => e
      Rails.logger.warn "Alto::ImageHelper: Rails URL generation failed: #{e.message}"
      # Fallback to a simple URL if Rails URL helpers fail
      "/rails/active_storage/blobs/#{image.key}/#{image.filename}"
    end

    # Converts size symbol to CSS class
    def size_to_css_class(size)
      case size
      when :thumbnail then 'max-h-32'
      when :small then 'max-h-48'
      when :medium then 'max-h-96'
      when :large then 'max-h-screen'
      else 'max-h-96'
      end
    end
  end
end
