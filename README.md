# FeedbackBoard Rails Engine

A mountable Rails engine for collecting user feedback with multiple boards, threaded comments, and voting.

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-red.svg)](https://rubyonrails.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](MIT-LICENSE)

## Features

- Multiple feedback boards (Bug Reports, Feature Requests, etc.)
- Ticket creation with 3-level threaded comments and upvoting
- Configurable status sets with custom statuses and colors
- Admin dashboard with status management and analytics
- Full-text search across tickets and comments
- Email notifications with beautiful HTML templates
- Callback hooks for integration with Slack, analytics, and external APIs

## Installation

Add to your Gemfile:

```ruby
gem 'feedback_board'
```

```bash
bundle install
```

## Setup

### 1. Mount the engine

Add to `config/routes.rb`:

```ruby
mount FeedbackBoard::Engine => "/feedback"
```

### 2. Run the installer

```bash
rails generate feedback_board:install
```

This creates:
- Database tables
- Configuration file at `config/initializers/feedback_board.rb`
- Stimulus controller (if using Hotwire)

**The installer is safe to run multiple times.**

### 3. Configure permissions (optional)

Edit `config/initializers/feedback_board.rb`:

```ruby
FeedbackBoard.configure do |config|
  # Restrict access to signed-in users
  config.permission :can_access_feedback_board? do
    user_signed_in?
  end

  # Only admins can access admin area
  config.permission :can_access_admin? do
    current_user&.admin?
  end

  # Customize user display names
  config.user_display_name do |user_id|
    User.find(user_id)&.full_name || "User ##{user_id}"
  end
end
```

## Basic Usage

### Navigation

```erb
<!-- Link to feedback board -->
<%= link_to "Feedback", feedback_board.root_path %>

<!-- Link to specific board -->
<%= link_to "Bug Reports", feedback_board.board_path("bugs") %>
```

### Admin Access

Visit `/feedback/admin` to:
- Manage boards
- Configure email notifications
- View analytics
- Change ticket statuses

## 🎣 Callback Hooks

One of FeedbackBoard's most powerful features is its callback hook system. The engine automatically calls methods in your host app when events occur, enabling seamless integration with external services.

### ⚙️ How It Works

Simply define methods in your `ApplicationController` and they'll be called automatically with full context:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  def ticket_created(ticket, board, user)
    # Called whenever a new ticket is submitted
    case board.slug
    when 'bugs'
      SlackNotifier.notify("#dev-team", "🐛 New bug: #{ticket.title}")
      BugTracker.create_issue(ticket, user)
    when 'features'
      Analytics.track(user&.id, 'feature_requested')
      ProductBoard.add_request(ticket)
    end
  end

  def comment_created(comment, ticket, board, user)
    # Called whenever someone comments
    NotificationMailer.new_comment(comment).deliver_later
  end
end
```

### 🔗 Available Hooks

**🎫 Ticket Events:**
- `ticket_created(ticket, board, user)` - New ticket submitted
- `ticket_status_changed(ticket, old_status, new_status, board, user)` - Status updated

**💬 Comment Events:**
- `comment_created(comment, ticket, board, user)` - New comment or reply
- `comment_deleted(comment, ticket, board, user)` - Comment removed

**👍 Voting Events:**
- `upvote_created(upvote, votable, board, user)` - Item upvoted
- `upvote_removed(upvote, votable, board, user)` - Upvote removed

### ✨ Why Callback Hooks?

- **⚡ Zero Configuration** - Just define the methods you need
- **📊 Rich Context** - Every callback receives the object, board, and user
- **🛡️ Error Isolation** - Callback failures don't break the main flow
- **🔌 Flexible Integration** - Works with any external service or internal logic

### 🚀 Common Use Cases

**💬 Slack/Discord Notifications:**
```ruby
def ticket_created(ticket, board, user)
  SlackWebhook.post(
    channel: board.slug == 'bugs' ? '#dev-team' : '#product',
    text: "New #{board.name}: #{ticket.title}",
    user: user&.email
  )
end
```

**📈 Analytics Tracking:**
```ruby
def ticket_created(ticket, board, user)
  Analytics.track(user&.id, 'feedback_submitted', {
    board: board.name,
    category: board.slug
  })
end
```

**🎫 External Ticketing:**
```ruby
def ticket_created(ticket, board, user)
  if board.slug == 'support'
    ZendeskAPI.create_ticket(
      subject: ticket.title,
      description: ticket.description,
      requester: user&.email
    )
  end
end
```

## Configuration

All configuration happens in `config/initializers/feedback_board.rb`. The installer creates this file with documented options.

### Common Options

```ruby
FeedbackBoard.configure do |config|
  # User model (default: "User")
  config.user_model = "Account"

  # User display names
  config.user_display_name do |user_id|
    User.find(user_id)&.name || "Anonymous"
  end

  # Permissions
  config.permission :can_create_tickets? do
    current_user.present?
  end

  config.permission :can_access_admin? do
    current_user&.admin?
  end

  # Email notifications
  config.notifications_enabled = true
  config.notify_admins_of_new_tickets = true
  config.admin_notification_emails = ["admin@example.com"]
end
```

### Email Setup

FeedbackBoard uses your app's existing ActionMailer configuration:

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  # your SMTP settings
}
```

Configure notification preferences in the admin dashboard at `/feedback/admin/settings`.

## Customization

### Styling

Override views by copying them to your app:

```bash
mkdir -p app/views/feedback_board/tickets
cp $(bundle show feedback_board)/app/views/feedback_board/tickets/* app/views/feedback_board/tickets/
```

The engine uses Tailwind CSS via CDN. To use your own CSS framework, override the layout:

```erb
<!-- app/views/layouts/feedback_board/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>Feedback</title>
    <%= csrf_meta_tags %>
    <%= stylesheet_link_tag "your-styles" %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

### Integrations

Add callback methods to your `ApplicationController` to integrate with external services:

```ruby
class ApplicationController < ActionController::Base
  private

  def ticket_created(ticket, board, user)
    # Post to Slack
    SlackNotifier.new_ticket(ticket) if board.slug == 'bugs'

    # Track in analytics
    Analytics.track(user&.id, 'ticket_created', board: board.name)
  end

  def comment_created(comment, ticket, board, user)
    # Email ticket author about new comment
    NotificationMailer.new_comment(comment).deliver_later
  end
end
```

Available callbacks:
- `ticket_created(ticket, board, user)`
- `ticket_status_changed(ticket, old_status, new_status, board, user)`
- `comment_created(comment, ticket, board, user)`
- `comment_deleted(comment, ticket, board, user)`
- `upvote_created(upvote, votable, board, user)`
- `upvote_removed(upvote, votable, board, user)`

## Troubleshooting

### "undefined method 'humanize'" error

This happens when ticket statuses are misconfigured. Run:

```bash
rails generate feedback_board:install
```

The installer will create any missing status configurations.

### Emails not sending

1. Verify ActionMailer is configured
2. Check admin settings at `/feedback/admin/settings`
3. Ensure `notifications_enabled = true` in your initializer

### Permission denied errors

Check your permission configuration in `config/initializers/feedback_board.rb`. The default permissions allow all access.

### Search not working

Ensure you've run the installer to create proper database indexes:

```bash
rails generate feedback_board:install
```

## Uninstall

```bash
rails generate feedback_board:uninstall
```

This will guide you through removing the engine and optionally cleaning up database tables.

## License

This gem is available under the MIT License.

### Comment Threading

The engine includes a sophisticated comment threading system with dedicated discussion pages:

**Features:**
- 🧵 **3-Level Threading** - Comments → Replies → Nested Replies (depth 0, 1, 2)
- 🎯 **Dedicated Thread Pages** - Each comment thread gets its own focused discussion page
- 👀 **Thread Previews** - Main ticket shows comment previews with reply counts
- 🔄 **Smart Navigation** - Seamless flow between ticket view and thread discussions
- ✅ **Clean UX** - No complex JavaScript, just standard form submissions

**URLs:**
```
/feedback/boards/features/tickets/123                  # Main ticket page
/feedback/boards/features/tickets/123/comments/456     # Comment thread discussion
```

**How it works:**
1. Users see comment previews on ticket pages with "View Thread & Reply (X replies)" links
2. Clicking takes them to dedicated thread discussion page
3. Users can reply directly in the focused thread environment
4. After replying, they're returned to the thread view with their new reply highlighted
5. Navigation breadcrumbs make it easy to return to the main ticket

**Thread Structure:**
```ruby
# Top-level comment (depth: 0)
comment = FeedbackBoard::Comment.create(
  ticket: ticket,
  content: "Great idea!",
  user_id: user.id
)

# Reply (depth: 1)
reply = FeedbackBoard::Comment.create(
  ticket: ticket,
  parent: comment,
  content: "I agree!",
  user_id: other_user.id
)

# Nested reply (depth: 2) - maximum depth
nested_reply = FeedbackBoard::Comment.create(
  ticket: ticket,
  parent: reply,
  content: "Same here!",
  user_id: another_user.id
)
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

**The install generator creates a comprehensive configuration file** at `config/initializers/feedback_board.rb` with all available options, examples, and documentation.

**All options are pre-configured with smart defaults** - just uncomment and customize what you need:

- **User & Permission Management** - Authentication, authorization, user display names
- **Email Notifications** - Admin emails, notification preferences
- **Board Configuration** - Default boards, deletion policies
- **Advanced Features** - Custom user models, display name logic, callback hooks

**Check the generated initializer file for the complete reference!** 📖

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

**Zero configuration required!** The engine includes built-in email notifications that work with your app's existing ActionMailer setup.

#### Features
- 📧 **New ticket notifications** - Admins get notified of new submissions
- 💬 **Comment notifications** - Ticket authors and admins get notified of new comments
- 📊 **Status change notifications** - Ticket authors get notified when status changes
- 🎨 **Beautiful email templates** - Professional HTML and text email designs
- ⚙️ **Admin configuration** - Toggle notifications and set admin emails via web interface
- 🚀 **Background processing** - Uses `deliver_later` for performance

#### Quick Setup

The email system uses your existing ActionMailer configuration. Just ensure ActionMailer is set up in your Rails app:

```ruby
# config/environments/production.rb (or development.rb)
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  user_name: ENV['GMAIL_USERNAME'],
  password: ENV['GMAIL_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

#### Admin Configuration

1. **Access admin area**: Visit `/feedback/admin` (requires admin permissions)
2. **Configure emails**: Go to Settings to set notification preferences
3. **Add admin emails**: Comma-separated list of emails to notify
4. **Toggle notifications**: Turn on/off different notification types
5. **Persistent settings**: All admin settings are saved to database and persist across restarts

#### Advanced Configuration

**Email settings are pre-configured in the generated initializer** at `config/initializers/feedback_board.rb`. All email notification options are documented and ready to customize - just uncomment what you need!

#### Admin Permissions

Add admin access to your ApplicationController:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # ... existing code ...

  private

  def can_access_admin?
    current_user&.admin?  # or your admin logic
  end
end
```

## 🎣 Host App Callback Hooks

**Hook into feedback board events with simple callback methods!** The engine automatically calls methods in your host app when events occur, giving you maximum integration flexibility.

### 📁 Where To Put Callbacks

Add these methods to your **host app's main ApplicationController**:

**File:** `app/controllers/application_controller.rb` (in your main app, not the engine)

### 🚀 Example Integration

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  # Example: Handle new tickets with board-specific logic
  def ticket_created(ticket, board, user)
    case board.slug
    when 'bugs'
      # Post to Slack dev channel
      Slack.notify("#dev-bugs", "🐛 Bug reported: #{ticket.title} by #{user&.email}")
      # Create issue in bug tracker
      BugTracker.create_issue(ticket, user)
      # Auto-assign to dev team
      ticket.update(assigned_team: 'development')
    when 'features'
      # Notify product team
      Slack.notify("#product", "💡 Feature request: #{ticket.title}")
      # Track in analytics
      Analytics.track(user&.id, 'feature_requested', board: board.name)
    when 'support'
      # Create Zendesk ticket
      ZendeskAPI.create_ticket(ticket)
      # Email support team
      SupportMailer.new_ticket(ticket).deliver_later
    end
  end
end
```

### 📋 All Available Callback Methods

```ruby
# Ticket Events
def ticket_created(ticket, board, user)
  # Called when a new ticket is submitted
  # Use for: Slack notifications, analytics, auto-assignment
end

def ticket_status_changed(ticket, old_status, new_status, board, user)
  # Called when ticket status changes (open → planned → in_progress → complete)
  # Use for: Progress tracking, completion notifications, roadmap updates
end

# Comment Events
def comment_created(comment, ticket, board, user)
  # Called when someone adds a comment or reply
  # Use for: Email notifications, @mention processing, engagement tracking
end

def comment_deleted(comment, ticket, board, user)
  # Called when a comment is deleted
  # Use for: Moderation logging, audit trails
end

# Upvote Events
def upvote_created(upvote, votable, board, user)
  # Called when someone upvotes a ticket or comment
  # Use for: Popular content alerts, analytics, trending detection
end

def upvote_removed(upvote, votable, board, user)
  # Called when someone removes their upvote
  # Use for: Vote change tracking, analytics
end
```

**Quick Reference:**
- **Tickets**: `ticket_created`, `ticket_status_changed`
- **Comments**: `comment_created`, `comment_deleted`
- **Upvotes**: `upvote_created`, `upvote_removed`

### 🛠 Setup Options

#### Option 1: In ApplicationController (Recommended)
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  def ticket_created(ticket, board, user)
    # Your integration code here
  end

  def comment_created(comment, ticket, board, user)
    # Your integration code here
  end

  # Add other callbacks as needed...
end
```

#### Option 2: In a Concern (For Complex Logic)
```ruby
# app/controllers/concerns/feedback_board_callbacks.rb
module FeedbackBoardCallbacks
  extend ActiveSupport::Concern

  private

  def ticket_created(ticket, board, user)
    FeedbackIntegration.handle_new_ticket(ticket, board, user)
  end

  def comment_created(comment, ticket, board, user)
    FeedbackIntegration.handle_new_comment(comment, ticket, board, user)
  end
end

# Then include in ApplicationController:
class ApplicationController < ActionController::Base
  include FeedbackBoardCallbacks
  # ... rest of your controller
end
```

#### Option 3: Dedicated Service Class
```ruby
# app/services/feedback_integration.rb
class FeedbackIntegration
  def self.handle_new_ticket(ticket, board, user)
    case board.slug
    when 'bugs'
      SlackNotifier.bug_reported(ticket, user)
    when 'features'
      ProductBoard.add_feature_request(ticket)
    end
  end
end

# In ApplicationController:
class ApplicationController < ActionController::Base
  private

  def ticket_created(ticket, board, user)
    FeedbackIntegration.handle_new_ticket(ticket, board, user)
  end
end
```

### ✅ Safety Features

- **Error Isolation**: If your callback method fails, it won't break ticket/comment creation
- **Automatic Detection**: Only calls methods that exist - no configuration needed
- **Logging**: Callback errors are logged for debugging
- **Zero Setup**: Just define the methods you want, ignore the ones you don't need

### 🧪 Quick Test

To verify callbacks are working, add this simple test:

```ruby
# In ApplicationController
def ticket_created(ticket, board, user)
  Rails.logger.info "🎫 Callback working! New ticket: #{ticket.title}"
  puts "🎫 Callback working! New ticket: #{ticket.title}"
end
```

Then create a ticket and check your Rails console/logs!

## 🛠 API Reference

### Models

#### FeedbackBoard::Board
```ruby
# Attributes
board.name             # String (required)
board.slug             # String (auto-generated, URL-friendly)
board.description      # Text (optional)
board.created_at       # DateTime
board.updated_at       # DateTime

# Associations
board.tickets          # HasMany tickets

# Methods
board.to_param         # Returns slug for URLs
board.tickets_count    # Integer (cached counter)

# Scopes
Board.by_slug(slug)    # Find by slug
Board.ordered          # Order by name
```

#### FeedbackBoard::Ticket
```ruby
# Attributes
ticket.title           # String
ticket.description     # Text
ticket.status          # String (open, planned, in_progress, complete)
ticket.locked          # Boolean
ticket.user_id         # Integer
ticket.board_id        # Integer (belongs to board)
ticket.created_at      # DateTime
ticket.updated_at      # DateTime

# Associations
ticket.board           # BelongsTo board
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
Ticket.for_board(board)      # Scope to specific board
```

#### FeedbackBoard::Comment
```ruby
# Attributes
comment.content        # Text
comment.user_id        # Integer
comment.ticket_id      # Integer (belongs to ticket)
comment.parent_id      # Integer (belongs to parent comment, optional)
comment.depth          # Integer (0=top-level, 1=reply, 2=nested reply)

# Associations
comment.ticket         # BelongsTo ticket
comment.parent         # BelongsTo parent comment (optional)
comment.replies        # HasMany replies (child comments)
comment.upvotes        # HasMany upvotes (polymorphic)

# Methods
comment.upvoted_by?(user)    # Boolean
comment.upvotes_count        # Integer
comment.can_be_voted_on?     # Boolean (checks if ticket is locked)
comment.can_be_replied_to?   # Boolean (checks depth < 2 and ticket not locked)
comment.is_reply?            # Boolean (has parent_id)
comment.thread_root          # Returns root comment of the thread

# Class Methods
Comment.threaded_for_ticket(ticket)  # Returns threaded structure for display
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
feedback_board.root_path                             # GET /feedback (redirects to default board)

# Board routes
feedback_board.boards_path                           # GET /feedback/boards (admin only)
feedback_board.board_path(board)                     # GET /feedback/boards/:slug
feedback_board.new_board_path                        # GET /feedback/boards/new (admin only)
feedback_board.edit_board_path(board)                # GET /feedback/boards/:slug/edit (admin only)

# Nested ticket routes under boards
feedback_board.board_tickets_path(board)             # GET /feedback/boards/:slug/tickets
feedback_board.new_board_ticket_path(board)          # GET /feedback/boards/:slug/tickets/new
feedback_board.board_ticket_path(board, ticket)      # GET /feedback/boards/:slug/tickets/:id
feedback_board.edit_board_ticket_path(board, ticket) # GET /feedback/boards/:slug/tickets/:id/edit

# Nested routes for comments and upvotes
feedback_board.board_ticket_comments_path(board, ticket)           # POST /feedback/boards/:slug/tickets/:id/comments
feedback_board.board_ticket_comment_path(board, ticket, comment)   # GET /feedback/boards/:slug/tickets/:id/comments/:id (thread view)
feedback_board.board_ticket_upvotes_path(board, ticket)            # POST /feedback/boards/:slug/tickets/:id/upvotes
feedback_board.comment_upvotes_path(comment)                       # POST /feedback/comments/:id/upvotes

# Admin routes
feedback_board.admin_root_path                       # GET /feedback/admin
feedback_board.admin_boards_path                     # GET /feedback/admin/boards
```

## 🔧 Troubleshooting

### Database Issues

**Missing database tables (feedback_board_comments, etc.)**

If you see errors like `relation "feedback_board_comments" does not exist`, the database tables weren't created properly.

**🎯 Primary Fix - Re-run install generator:**
```bash
rails generate feedback_board:install
```
*The generator checks what exists and only creates what's missing - completely safe to re-run!*

**🔍 Alternative - Check table status:**
```bash
rails feedback_board:status
```

**🛠️ Alternative - Direct database setup:**
```bash
rails feedback_board:setup
```

**🔄 Nuclear option - Reset everything (destroys data):**
```bash
rails feedback_board:reset
```

**💡 When database issues happen:**
- After `rails db:drop` or `rails db:reset`
- When switching between development environments
- After engine updates or changes
- During initial setup

**The install generator is now smart enough to handle all these scenarios gracefully!** ✨

### Common Issues

**1. Missing current_user method**
```ruby
# Add to ApplicationController
def current_user
  # Your user logic here
  @current_user ||= User.find(session[:user_id]) if session[:user_id]
end
```

**2. AJAX voting not working**
- Check browser console for JavaScript errors
- Ensure `csrf_meta_tags` is in your layout
- Verify Rails UJS is loaded (included automatically)

**3. Permission errors**
- Implement the permission methods shown above
- Check that `current_user` returns the expected user object

**4. Styling issues**
- Ensure Tailwind CSS is available
- Copy and customize views if needed
- Check CSS load order

**5. Need to remove FeedbackBoard?**
- Use the uninstall generator: `rails generate feedback_board:uninstall`
- It will safely guide you through the removal process
- See the [Uninstallation](#-uninstallation) section above for details

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
- AJAX interactions via built-in vanilla JavaScript

---

**Need help?** Open an issue or check the [examples directory](examples/) for more integration patterns!
