# 📷 Image Uploads in Alto

This guide explains how to enable and configure image uploads in Alto, allowing users to attach images to tickets and comments.

## ✨ Features

- **One image per post**: Users can attach a single image to tickets and comments
- **File validation**: Automatic validation for file size (5MB max) and type (JPEG, PNG, GIF, WebP)
- **Direct uploads**: Uses ActiveStorage direct uploads for better performance
- **Smart storage detection**: Automatically adapts to your existing ActiveStorage configuration
- **Multi-service support**: Works with Cloudinary, S3, and local storage
- **Size variants**: Supports thumbnail, small, medium, and large image sizes
- **Simple UI**: Clean, intuitive upload interface integrated into existing forms

## 🚀 Quick Setup

### 1. Enable Alto Configuration

In `config/initializers/alto.rb`, uncomment:

```ruby
Alto.configure do |config|
  config.image_uploads_enabled = true
end
```

### 2. Configure Your Storage Service

Alto automatically detects and adapts to your existing ActiveStorage configuration. Choose your preferred storage:

#### Option A: Cloudinary (Recommended)

Add to your `Gemfile`:
```ruby
gem 'cloudinary'
gem 'activestorage-cloudinary-service'
```

Configure `config/storage.yml`:
```yaml
cloudinary:
  service: Cloudinary
  cloud_name: <%= Rails.application.credentials.dig(:cloudinary, :cloud_name) %>
  api_key: <%= Rails.application.credentials.dig(:cloudinary, :api_key) %>
  api_secret: <%= Rails.application.credentials.dig(:cloudinary, :api_secret) %>
```

#### Option B: Amazon S3

```yaml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: your-bucket-name
```

#### Option C: Local Storage (Development)

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

Set your chosen service in your environment:
```ruby
# config/environments/production.rb
config.active_storage.service = :cloudinary  # or :amazon

# config/environments/development.rb
config.active_storage.service = :local  # or your preferred service
```

### 3. Add JavaScript Support (Optional)

For direct uploads, add to your `app/javascript/application.js`:

```javascript
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

## 🎨 How It Works

### For Users

1. **Creating tickets**: An optional "Attach Image" field appears in the ticket form
2. **Adding comments**: Similar image upload field in comment forms
3. **Viewing images**: Images display inline with content, click to view full size
4. **Updating tickets**: Can replace existing images when editing

### Technical Details

- Uses `has_many_attached :images` for flexibility (backend supports multiple images)
- UI enforces single image through `multiple: false` on file inputs
- Validates file size (5MB max) and type (image formats only)
- **Smart service detection**: Automatically detects your ActiveStorage service configuration
- **Cloudinary**: Uses direct URLs without Rails variants for optimal performance
- **S3/Local**: Uses Rails variants for image resizing when needed
- **Size support**: Pass `size: :thumbnail/:small/:medium/:large` to image partials

## 🔧 Configuration

### Using Different Image Sizes

You can specify different image sizes when rendering images:

```erb
<!-- In your views -->
<%= render 'alto/shared/attached_image', record: @ticket, size: :thumbnail %>
<%= render 'alto/shared/attached_image', record: @ticket, size: :small %>
<%= render 'alto/shared/attached_image', record: @ticket, size: :medium %>  <!-- default -->
<%= render 'alto/shared/attached_image', record: @ticket, size: :large %>

<!-- Custom size -->
<%= render 'alto/shared/attached_image', record: @ticket, size: { width: 400, height: 300 } %>
```

Available sizes:
- `:thumbnail` - 150x150px max
- `:small` - 300x300px max
- `:medium` - 600x400px max (default)
- `:large` - 1200x800px max

### Custom Image Size Limits

To change the 5MB limit, modify the concern:

```ruby
# In an initializer
module Alto
  module ImageAttachable
    def acceptable_image_size
      return unless images.attached?

      images.each do |image|
        if image.byte_size > 10.megabytes  # Your custom limit
          errors.add(:images, "#{image.filename} is too large (maximum is 10MB)")
        end
      end
    end
  end
end
```

### Allow Multiple Images

If you want to allow multiple images per post:

```ruby
# In an initializer or monkey patch
module Alto
  class Ticket
    def enforce_single_image?
      false  # Allow multiple images
    end
  end
end
```

Then update forms to use `multiple: true`:
```erb
<%= form.file_field :images, multiple: true, accept: "image/*" %>
```

## 🚨 Troubleshooting

### Images Not Uploading

1. Check that ActiveStorage is installed: `rails active_storage:install && rails db:migrate`
2. Verify `config.image_uploads_enabled = true` in your initializer
3. Check Rails logs for storage service errors
4. Ensure Cloudinary credentials are properly configured

### Images Not Displaying

1. Check Cloudinary configuration and credentials
2. Verify storage service is set correctly in environment files
3. Check browser network tab for image loading errors

## 🔒 Security Considerations

- File type validation prevents non-image uploads
- Size limits prevent abuse (5MB default)
- Direct uploads bypass your Rails server for better performance
- Cloudinary provides automatic optimization and virus scanning
- Consider rate limiting for uploads in production

## 🎯 Best Practices

1. **Choose the right service**:
   - **Cloudinary**: Best for production with automatic optimization
   - **S3**: Good for high-volume applications with custom processing needs
   - **Local**: Perfect for development and testing
2. **Direct uploads**: Configure for better user experience and server performance
3. **Monitor usage**: Track storage service usage and costs
4. **Image guidelines**: Provide users with image size/format recommendations
5. **Size appropriately**: Use smaller sizes (thumbnail/small) for lists, larger for detail views
6. **Fallback handling**: Graceful degradation if images fail to load

## 📚 Additional Resources

- [ActiveStorage Guide](https://guides.rubyonrails.org/active_storage_overview.html)
- [Cloudinary Rails Integration](https://cloudinary.com/documentation/rails_integration)
- [Direct Uploads Guide](https://guides.rubyonrails.org/active_storage_overview.html#direct-uploads)
