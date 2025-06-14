require 'test_helper'

module Alto
  class ImageAttachableTest < ActiveSupport::TestCase
    def setup
      Alto.configuration.image_uploads_enabled = true
      @ticket = alto_tickets(:one)
      @comment = alto_comments(:one)

      # Create a test image blob
      @image_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("fake image data"),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
    end

    test "ticket purges images when destroyed" do
      @ticket.images.attach(@image_blob)
      assert @ticket.images.attached?

      # Mock the purge method to verify it's called
      @ticket.images.expects(:purge).once
      @ticket.destroy
    end

    test "comment purges images when destroyed" do
      @comment.images.attach(@image_blob)
      assert @comment.images.attached?

      # Mock the purge method to verify it's called
      @comment.images.expects(:purge).once
      @comment.destroy
    end

    test "purge_attached_images method exists and works" do
      @ticket.images.attach(@image_blob)
      assert @ticket.images.attached?

      # Test the method directly
      assert_respond_to @ticket, :purge_attached_images

      # Mock purge to verify it's called
      @ticket.images.expects(:purge).once
      @ticket.send(:purge_attached_images)
    end

    test "purge_attached_images handles no images gracefully" do
      assert_not @ticket.images.attached?

      # Should not raise an error
      assert_nothing_raised do
        @ticket.send(:purge_attached_images)
      end
    end

    test "image validation still works with purge callback" do
      # Test that our purge callback doesn't interfere with validations
      large_blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("x" * 6.megabytes),
        filename: "large.jpg",
        content_type: "image/jpeg"
      )

      @ticket.images.attach(large_blob)
      assert_not @ticket.valid?
      assert_includes @ticket.errors[:images], "large.jpg is too large (maximum is 5MB)"
    end
  end
end
