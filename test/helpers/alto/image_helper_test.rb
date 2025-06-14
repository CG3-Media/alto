require 'test_helper'

module Alto
  class ImageHelperTest < ActionView::TestCase
    include Alto::ImageHelper

    def setup
      @ticket = alto_tickets(:one)
      @image_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("fake image data"),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
    end

        test "should_display_images? returns false when image uploads disabled" do
      Alto.configuration.image_uploads_enabled = false
      result = should_display_images?(@ticket)
      assert_equal false, result
    end

    test "should_display_images? returns false when record has no images" do
      Alto.configuration.image_uploads_enabled = true
      result = should_display_images?(@ticket)
      assert_equal false, result
    end

    test "should_display_images? returns true when images present and enabled" do
      Alto.configuration.image_uploads_enabled = true
      @ticket.images.attach(@image_blob)

      result = should_display_images?(@ticket)
      assert_equal true, result
    end

    test "image_display_data returns correct data structure" do
      @ticket.images.attach(@image_blob)

      result = image_display_data(@image_blob, size: :small)
      assert_not_nil result
      assert_includes result.keys, :image_url
      assert_includes result.keys, :full_size_url
      assert_includes result.keys, :filename
      assert_includes result.keys, :file_size
      assert_includes result.keys, :size_class
      assert_equal 'test.jpg', result[:filename]
    end

        test "detect_storage_service identifies different services from host app config" do
      # Mock different service configurations
      original_service = Rails.application.config.active_storage.service
      original_config = Rails.application.config.active_storage.service_configurations

      # Test Cloudinary detection
      Rails.application.config.active_storage.service_configurations = {
        'test' => { 'service' => 'Cloudinary' }
      }
      Rails.application.config.active_storage.service = :test
      assert_equal :cloudinary, detect_storage_service

      # Test S3 detection
      Rails.application.config.active_storage.service_configurations = {
        'test' => { 'service' => 'S3' }
      }
      assert_equal :s3, detect_storage_service

      # Test local fallback
      Rails.application.config.active_storage.service_configurations = {
        'test' => { 'service' => 'Disk' }
      }
      assert_equal :local, detect_storage_service

      # Restore original config
      Rails.application.config.active_storage.service = original_service
      Rails.application.config.active_storage.service_configurations = original_config
    end

        test "size_to_css_class returns correct classes" do
      assert_equal 'max-h-32', size_to_css_class(:thumbnail)
      assert_equal 'max-h-48', size_to_css_class(:small)
      assert_equal 'max-h-96', size_to_css_class(:medium)
      assert_equal 'max-h-screen', size_to_css_class(:large)
      assert_equal 'max-h-96', size_to_css_class(:unknown)
    end

    test "DEFAULT_SIZES contains expected size configurations" do
      assert_equal 150, Alto::ImageHelper::DEFAULT_SIZES[:thumbnail][:width]
      assert_equal 300, Alto::ImageHelper::DEFAULT_SIZES[:small][:width]
      assert_equal 600, Alto::ImageHelper::DEFAULT_SIZES[:medium][:width]
      assert_equal 1200, Alto::ImageHelper::DEFAULT_SIZES[:large][:width]
    end

    private

    def number_to_human_size(size)
      # Simple mock for testing
      "#{size} bytes"
    end

    def content_tag(tag, content = nil, options = {}, &block)
      # Simple mock for testing
      if block_given?
        "<#{tag}>#{yield}</#{tag}>"
      else
        "<#{tag}>#{content}</#{tag}>"
      end
    end

    def image_tag(src, options = {})
      # Simple mock for testing
      "<img src='#{src}' />"
    end

    def link_to(url, options = {}, &block)
      # Simple mock for testing
      if block_given?
        "<a href='#{url}'>#{yield}</a>"
      else
        "<a href='#{url}'>#{options}</a>"
      end
    end
  end
end
