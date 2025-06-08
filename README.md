# FeedbackBoard Rails Engine

A mountable Rails engine that replicates core Canny.io-style feedback functionality for your app. Users can submit tickets, comment, vote, and admins can manage status and moderation.

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-red.svg)](https://rubyonrails.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](MIT-LICENSE)

## ✨ Features

- 🎫 **Ticket Management** - Create, view, and manage feedback tickets
- 💬 **Comments** - Threaded discussions on tickets
- 👍 **Upvoting** - Users can vote on tickets and comments (with AJAX)
- 📊 **Status Tracking** - `open`, `planned`, `in_progress`, `complete`
- 🔒 **Moderation** - Lock tickets to prevent further discussion
- 🎨 **Beautiful UI** - Clean Tailwind CSS design
- 🔐 **Permissions** - Flexible permission system
- ⚡ **Performance** - Optimized queries and database indexes

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'feedback_board'
gem 'stimulus-rails', '>= 1.0'  # Required for AJAX voting
```

And then execute:
```bash
bundle install
```

## ⚙️ Setup

### 1. Run the installer
```bash
rails generate feedback_board:install
```

### 2. Add routes
Add to your `config/routes.rb`:
```ruby
mount FeedbackBoard::Engine => "/feedback"
```

### 3. Run migrations
```bash
rails feedback_board:install:migrations
rails db:migrate
```

### 4. Setup Stimulus (for AJAX voting)

#### For Vite Apps:
Copy the Stimulus controller:
```bash
cp $(bundle show feedback_board)/app/assets/javascripts/feedback_board/controllers/upvote_controller.js app/frontend/controllers/
```

Register it in `app/frontend/controllers/index.js`:
```javascript
import UpvoteController from "./upvote_controller"
application.register("upvote", UpvoteController)
```

#### For Asset Pipeline Apps:
Copy the Stimulus controller:
```bash
cp $(bundle show feedback_board)/app/assets/javascripts/feedback_board/controllers/upvote_controller.js app/javascript/controllers/
```

Register it in `app/javascript/controllers/index.js`:
```javascript
import UpvoteController from "./upvote_controller"
application.register("upvote", UpvoteController)
```

### 5. Configure permissions (see below)

## 🔐 Permissions System

**Zero configuration required!** The engine works out of the box with sensible defaults.

To customize permissions, simply add these methods to your `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # ... your existing code ...

  private

  # Optional: Control who can access the feedback board
  def can_access_feedback_board?
    user_signed_in?  # Default: true (if current_user exists)
  end

  # Optional: Control who can submit new tickets
  def can_submit_tickets?
    user_signed_in?  # Default: true (if current_user exists)
  end

  # Optional: Control who can comment on tickets
  def can_comment?
    user_signed_in?  # Default: true (if current_user exists)
  end

  # Optional: Control who can vote on tickets/comments
  def can_vote?
    user_signed_in?  # Default: true (if current_user exists)
  end

  # Optional: Control who can edit tickets (status, lock, etc.)
  def can_edit_tickets?
    current_user&.admin?  # Default: false (secure by default)
  end
end
```

### Alternative: Use a Concern (Optional)

For better organization, you can also use a concern:

```ruby
# app/controllers/concerns/feedback_board_permissions.rb
module FeedbackBoardPermissions
  extend ActiveSupport::Concern

  private

  def can_edit_tickets?
    current_user&.admin?
  end

  # ... other permission methods ...
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include FeedbackBoardPermissions
  # ... rest of your code ...
end
```

## 📱 Usage Examples

### Basic Integration

```erb
<!-- In your app's navigation -->
<%= link_to "Feedback", feedback_board.root_path, class: "nav-link" %>

<!-- Or embed directly -->
<iframe src="/feedback" width="100%" height="600"></iframe>
```

### User Association

The engine expects a `current_user` method. If you use Devise:

```ruby
# This works automatically with Devise
def current_user
  super
end
```

For custom authentication:
```ruby
def current_user
  @current_user ||= User.find(session[:user_id]) if session[:user_id]
end
```

### Custom User Model Integration

If your user model doesn't have an `id` field or uses UUIDs:

```ruby
# Override in your ApplicationController
def current_user_id
  current_user&.uuid || current_user&.id
end
```

### User Display Names 👤

By default, the engine will try to display user names in comments by checking for:
1. `full_name` field
2. `first_name` + `last_name` fields
3. `first_name` only
4. `last_name` only
5. `email` as fallback
6. "User #ID" as final fallback

You can customize this completely in your initializer (see Configuration Options below).

## 🎨 Customization

### Styling

The engine uses Tailwind CSS via CDN for maximum compatibility. To customize:

**For Vite users:** The engine loads Tailwind via CDN to avoid asset pipeline conflicts. If you want to use your own Tailwind build, override the layout:

```erb
<!-- app/views/layouts/feedback_board/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>Feedback Board</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <!-- Use your Vite assets instead of CDN -->
    <%= vite_client_tag %>
    <%= vite_javascript_tag 'application' %>
    <%= vite_stylesheet_tag 'application' %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

1. **Override views**: Copy views to your app
```bash
mkdir -p app/views/feedback_board/tickets
cp $(bundle show feedback_board)/app/views/feedback_board/tickets/* app/views/feedback_board/tickets/
```

2. **Custom CSS**: Add your styles
```scss
// app/assets/stylesheets/feedback_board_custom.scss
.feedback-board {
  // Your custom styles
}
```

3. **Different CSS Framework**: Override the layout
```erb
<!-- app/views/layouts/feedback_board/application.html.erb -->
<%= content_for :head do %>
  <%= stylesheet_link_tag "your-framework" %>
<% end %>
```

### Configuration Options

```ruby
# config/initializers/feedback_board.rb (create this file)
FeedbackBoard.configure do |config|
  # Specify your user model (defaults to "User")
  config.user_model = "User"  # or "Account", "Member", etc.

  # Customize how user names are displayed in comments
  # This proc receives a user_id and should return a display name string
  config.user_display_name_method = proc do |user_id|
    user = User.find_by(id: user_id)
    return "Anonymous" unless user

    # Your custom logic here - try name fields, fallback to email
    if user.full_name.present?
      user.full_name
    elsif user.first_name.present? || user.last_name.present?
      "#{user.first_name} #{user.last_name}".strip
    elsif user.email.present?
      user.email
    else
      "User ##{user_id}"
    end
  end

  # Other examples for different user models:

  # For Devise with display_name field:
  # config.user_display_name_method = proc do |user_id|
  #   user = User.find_by(id: user_id)
  #   user&.display_name || user&.email || "Anonymous"
  # end

  # For username-based systems:
  # config.user_display_name_method = proc do |user_id|
  #   user = User.find_by(id: user_id)
  #   user&.username || "Anonymous"
  # end

  # For systems with profile models:
  # config.user_display_name_method = proc do |user_id|
  #   user = User.find_by(id: user_id)
  #   return "Anonymous" unless user
  #   user.profile&.display_name || user.email
  # end
end
```

### Status Customization

```ruby
# In the same config/initializers/feedback_board.rb file
FeedbackBoard.configure do |config|
  # ... user display name config above ...

  # Custom statuses (optional) - Coming soon!
  # config.statuses = %w[open planned in_progress complete closed]

  # Custom status colors (optional) - Coming soon!
  # config.status_colors = {
  #   'open' => 'bg-green-100 text-green-800',
  #   'planned' => 'bg-blue-100 text-blue-800',
  #   'in_progress' => 'bg-yellow-100 text-yellow-800',
  #   'complete' => 'bg-gray-100 text-gray-800',
  #   'closed' => 'bg-red-100 text-red-800'
  # }
end
```

### Email Notifications

```ruby
# Create a mailer in your app
class FeedbackNotificationMailer < ApplicationMailer
  def new_ticket(ticket)
    @ticket = ticket
    mail(to: admin_emails, subject: "New Feedback: #{@ticket.title}")
  end

  def new_comment(comment)
    @comment = comment
    @ticket = comment.ticket
    mail(to: admin_emails, subject: "New Comment on: #{@ticket.title}")
  end
end

# Hook into callbacks
# app/models/concerns/feedback_board_notifications.rb
module FeedbackBoardNotifications
  extend ActiveSupport::Concern

  included do
    after_create :send_notification
  end

  private

  def send_notification
    if self.is_a?(FeedbackBoard::Ticket)
      FeedbackNotificationMailer.new_ticket(self).deliver_later
    elsif self.is_a?(FeedbackBoard::Comment)
      FeedbackNotificationMailer.new_comment(self).deliver_later
    end
  end
end

# Include in the models
FeedbackBoard::Ticket.include FeedbackBoardNotifications
FeedbackBoard::Comment.include FeedbackBoardNotifications
```

## 🛠 API Reference

### Models

#### FeedbackBoard::Ticket
```ruby
# Attributes
ticket.title           # String
ticket.description     # Text
ticket.status          # String (open, planned, in_progress, complete)
ticket.locked          # Boolean
ticket.user_id         # Integer
ticket.created_at      # DateTime
ticket.updated_at      # DateTime

# Associations
ticket.comments        # HasMany comments
ticket.upvotes         # HasMany upvotes (polymorphic)

# Methods
ticket.upvoted_by?(user)     # Boolean
ticket.upvotes_count         # Integer
ticket.can_be_voted_on?      # Boolean
ticket.can_be_commented_on?  # Boolean

# Scopes
Ticket.by_status('open')     # Filter by status
Ticket.recent                # Order by created_at desc
Ticket.popular               # Order by upvotes count
Ticket.unlocked              # Not locked
```

#### FeedbackBoard::Comment
```ruby
# Attributes
comment.content        # Text
comment.user_id        # Integer
comment.ticket_id      # Integer (belongs to ticket)

# Associations
comment.ticket         # BelongsTo ticket
comment.upvotes        # HasMany upvotes (polymorphic)

# Methods
comment.upvoted_by?(user)    # Boolean
comment.upvotes_count        # Integer
comment.can_be_voted_on?     # Boolean (checks if ticket is locked)
```

#### FeedbackBoard::Upvote
```ruby
# Attributes
upvote.user_id         # Integer
upvote.upvotable_type  # String (Ticket or Comment)
upvote.upvotable_id    # Integer
```

### Routes

```ruby
# All routes are namespaced under the mount point
feedback_board.root_path                    # GET /feedback
feedback_board.tickets_path                 # GET /feedback/tickets
feedback_board.new_ticket_path              # GET /feedback/tickets/new
feedback_board.ticket_path(ticket)          # GET /feedback/tickets/:id
feedback_board.edit_ticket_path(ticket)     # GET /feedback/tickets/:id/edit

# Nested routes
feedback_board.ticket_comments_path(ticket)           # POST /feedback/tickets/:id/comments
feedback_board.ticket_upvotes_path(ticket)            # POST /feedback/tickets/:id/upvotes
feedback_board.comment_upvotes_path(comment)          # POST /feedback/comments/:id/upvotes
```

## 🔧 Troubleshooting

### Common Issues

**1. Missing current_user method**
```ruby
# Add to ApplicationController
def current_user
  # Your user logic here
  @current_user ||= User.find(session[:user_id]) if session[:user_id]
end
```

**2. Stimulus not working**
- Ensure `stimulus-rails` is in your Gemfile
- Verify the controller is copied and registered
- Check browser console for JavaScript errors
- Ensure `csrf_meta_tags` is in your layout

**3. Permission errors**
- Implement the permission methods shown above
- Check that `current_user` returns the expected user object

**4. Styling issues**
- Ensure Tailwind CSS is available
- Copy and customize views if needed
- Check CSS load order

### Development

```bash
# Run tests
bundle exec rails test

# Check code style
bundle exec rubocop

# Generate documentation
bundle exec yard doc
```

## 🤝 Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## 📄 License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

## 🙏 Acknowledgments

- Inspired by [Canny.io](https://canny.io) feedback functionality
- Built with Rails Engines best practices
- UI powered by Tailwind CSS
- AJAX interactions via Stimulus

---

**Need help?** Open an issue or check the [examples directory](examples/) for more integration patterns!
