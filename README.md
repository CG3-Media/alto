<img width="1663" alt="image" src="https://github.com/user-attachments/assets/4e17ab33-cb16-42ef-b514-725344b7ee0b" />

# FeedbackBoard Rails Engine

A mountable Rails engine for collecting user feedback with multiple boards, threaded comments, and voting.

> **⚠️ AI-Generated Code Disclaimer**
> This entire engine was coded by AI with human oversight. While we've taken precautions during development and thoroughly tested the functionality, please use at your own risk and conduct your own testing before deploying to production.

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-red.svg)](https://rubyonrails.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](MIT-LICENSE)

## Features

- Multiple feedback boards (Bug Reports, Feature Requests, etc.)
- Ticket creation with 3-level threaded comments and upvoting
- Configurable status sets with custom statuses and colors
- Admin dashboard with status management and analytics
- Full-text search across tickets and comments
- Callback hooks for integration with email notifications, Slack, analytics, and external APIs

## Installation

Add to your Gemfile:

```ruby
gem 'feedback_board', github: 'CG3-Media/feedback_board'
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
- View analytics
- Change ticket statuses

## 🎣 Callback Hooks

One of FeedbackBoard's most powerful features is its callback hook system. The engine automatically calls methods in your host app when events occur, enabling seamless integration with external services.

### ⚙️ How It Works

Define callback methods in your **ApplicationController** (not config) - they need access to controller context like `current_user`:

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
    # Send email notifications using your preferred method
    UserMailer.new_comment_notification(comment, ticket, user).deliver_later
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

### 📍 Where to Define Callbacks

**✅ ApplicationController (Recommended)** - Callbacks need controller context:
```ruby
# app/controllers/application_controller.rb - ✅ YES
class ApplicationController < ActionController::Base
  private

  def ticket_created(ticket, board, user)
    # Has access to current_user, request, session, etc.
  end
end
```

**❌ NOT in config/initializers** - No access to request context:
```ruby
# config/initializers/feedback_board.rb - ❌ NO
# This won't work - no access to current_user or controller helpers
```

**🗂️ Alternative: Use a Concern for organization:**
```ruby
# app/controllers/concerns/feedback_board_callbacks.rb
module FeedbackBoardCallbacks
  extend ActiveSupport::Concern

  private

  def ticket_created(ticket, board, user)
    FeedbackIntegrationService.handle_new_ticket(ticket, board, user)
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include FeedbackBoardCallbacks
end
```

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

**🔓 Authentication-Agnostic** - FeedbackBoard works with ANY authentication system (or none at all):
- ✅ Devise
- ✅ Custom authentication
- ✅ JWT tokens
- ✅ Session-based auth
- ✅ No authentication (public feedback)

### Common Options

```ruby
FeedbackBoard.configure do |config|
  # User model (default: "User")
  config.user_model = "Account"

  # User display names
  config.user_display_name do |user_id|
    User.find(user_id)&.name || "Anonymous"
  end

  # Permissions (works with any auth system)
  config.permission :can_create_tickets? do
    current_user.present?  # Devise, custom auth, etc.
  end

  config.permission :can_access_admin? do
    current_user&.admin?  # Your admin logic here
  end

  # Board configuration
  config.allow_board_deletion_with_tickets = false
end
```

### Authentication Examples

```ruby
# Devise - works automatically
config.permission :can_create_tickets? do
  user_signed_in?
end

# Custom auth - define current_user in ApplicationController
config.permission :can_create_tickets? do
  current_user.present?
end

# Public feedback (no auth required)
config.permission :can_create_tickets? do
  true
end
```

### Email Notifications

Email notifications are handled through the callback system. Implement callback methods in your ApplicationController to send notifications using your preferred mailer:

```ruby
# app/controllers/application_controller.rb
def ticket_created(ticket, board, user)
  # Send email using your mailer
  UserMailer.ticket_created(ticket, user).deliver_later
end

def comment_created(comment, ticket, board, user)
  # Notify ticket author of new comments
  if ticket.user_id != user&.id
    UserMailer.new_comment(comment, ticket).deliver_later
  end
end
```

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

See the [Callback Hooks](#-callback-hooks) section for integrating with external services like Slack, analytics, and ticketing systems.

## Troubleshooting

### "undefined method 'humanize'" error

This happens when ticket statuses are misconfigured. Run:

```bash
rails generate feedback_board:install
```

The installer will create any missing status configurations.

### Email notifications not working

Email notifications are handled through callback methods in your ApplicationController. Ensure you've implemented the callback methods you need:

```ruby
# app/controllers/application_controller.rb
def ticket_created(ticket, board, user)
  # Your email notification logic here
end
```

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
