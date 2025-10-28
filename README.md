# ⚠️ Development Status
Note: This gem is currently in early beta. But try it out (on some non-critical apps)!

# Alto Rails Engine

**Demo available on: https://cg3-media.github.io/alto-site/**

Alto is a mountable Rails engine for collecting user feedback with multiple boards, threaded comments, and voting.

> **⚠️ AI-Generated Code Disclaimer**
> This engine contains code written by AI.

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-red.svg)](https://rubyonrails.org)

## Features

- Multiple feedback boards (Bug Reports, Feature Requests, etc.)
- Customizable item labels per board ("tickets", "posts", "bugs", "requests", etc.)
- Custom fields per board (dropdowns, text inputs, multiselect, etc.)
- Ticket creation with 3-level threaded comments and upvoting
- **Image upload support** for tickets and comments with automatic cloud storage optimization
- Configurable status sets with custom statuses and colors
- Admin dashboard with status management and analytics
- Full-text search across tickets and comments
- Callback hooks for integration with email notifications, Slack, analytics, and external APIs

## Installation

Add to your Gemfile:

```ruby
gem 'alto', github: 'CG3-Media/alto'
```

```bash
bundle install
```

## Setup

### 1. Mount the engine

Add to `config/routes.rb`:

```ruby
mount Alto::Engine => "/community" # e.g. or /feedback or whatever
```

### 2. Run the installer

```bash
rails generate alto:install
```

This creates:
- Database tables (using your app's main database)
- Configuration file at `config/initializers/alto.rb`
- Default feedback boards

**The installer is safe to run multiple times.**

Alto uses the standard Rails engine pattern - all tables are stored in your main database with the `alto_` prefix to avoid conflicts.

### 3. Configure permissions

Edit `config/initializers/alto.rb`:

```ruby
Alto.configure do |config|
  # Restrict access to signed-in users
  config.permission :can_access_alto? do
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
<%= link_to "Feedback", alto.alto_home_path %>

<!-- Link to specific board -->
<%= link_to "Bug Reports", alto.board_path("bugs") %>
```

## Image Support

Alto supports image uploads for tickets and comments. Works with Cloudinary, S3, or local storage.

```ruby
# config/initializers/alto.rb
Alto.configure do |config|
  config.image_uploads_enabled = true
end
```

Requires ActiveStorage to be configured in your Rails app. Images are automatically optimized and cleaned up when records are deleted.

## 🎣 Callback Hooks

One of Alto's most powerful features is its callback hook system. The engine automatically calls methods in your host app when events occur, enabling seamless integration with external services.

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

**🗂️ Use a Concern for organization:**
```ruby
# app/controllers/concerns/alto_callbacks.rb
module AltoCallbacks
  extend ActiveSupport::Concern

  private

  def ticket_created(ticket, board, user)
    FeedbackIntegrationService.handle_new_ticket(ticket, board, user)
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include AltoCallbacks
end
```

### 🚀 Common Use Cases

**💬 Slack/Discord/Email Notifications:**
```ruby
def ticket_created(ticket, board, user)
  SlackWebhook.post(
    channel: board.slug == 'bugs' ? '#dev-team' : '#product',
    text: "New #{board.name}: #{ticket.title}",
    user: user&.email
  )

  # Send email notification
  UserMailer.alto_notification(
    to: board.admin_email,
    subject: "New ticket: #{ticket.title}",
    ticket: ticket,
    user: user
  ).deliver_later
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

All configuration happens in `config/initializers/alto.rb`. The installer creates this file with documented options.

**🔓 Authentication-Agnostic** - Alto works with ANY authentication system (or none at all):
- ✅ Devise
- ✅ Custom authentication
- ✅ JWT tokens
- ✅ Session-based auth
- ✅ No authentication (public feedback)

### Common Options

```ruby
Alto.configure do |config|
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

  # Image uploads (requires ActiveStorage)
  config.image_uploads_enabled = true

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


## Widget System

Generate embeddable widgets for any board:

```bash
rails generate alto:widget
```

This creates a partial at `app/views/shared/alto/_BOARD_widget.html.erb` that you can embed anywhere:

```erb
<!-- In any view -->
<%= render 'shared/alto/feature_requests_widget' %>
```

The generated widget is a complete feedback form using your board's custom fields. Customize the HTML/CSS as needed!

## Customization

### Styling

For simplicity, we're using tailwind via a CDN. 🤷🏾‍♂️

### Integrations

Alto integrates seamlessly with your existing Rails application through its callback hook system. Common integration patterns include:

- **Slack/Discord Notifications** - Notify teams of new tickets and comments
- **Email Notifications** - Send updates to stakeholders and users
- **Analytics Tracking** - Track user engagement and feedback patterns
- **External Ticketing** - Sync with Zendesk, Jira, or other systems
- **Custom Business Logic** - Trigger workflows based on feedback events

See the [Callback Hooks](#-callback-hooks) section above for implementation examples.

## 🔗 Polymorphic User Architecture

Alto uses Rails polymorphic associations to support **any user model** in your host application. This flexible design allows the engine to work with different user model names across different applications.

### 🏗️ How It Works

The engine stores user references using two columns:
- `user_id` - The ID of the user record
- `user_type` - The class name of your user model (e.g., "User", "Account", "Member")

This is automatically configured based on your initializer:

```ruby
# config/initializers/alto.rb
Alto.configure do |config|
  config.user_model = "User"        # → user_type = "User"
  # config.user_model = "Account"   # → user_type = "Account"
  # config.user_model = "Member"    # → user_type = "Member"
end
```



### Permission denied errors

Check your permission configuration in `config/initializers/alto.rb`. The default permissions allow all access.


## Uninstall

```bash
rails generate alto:uninstall
```

This will guide you through removing the engine and optionally cleaning up database tables.


## License

Alto Custom License v1.0
Copyright (c) 2025 CG3 Media, LLC

You are free to use, copy, modify, and deploy this software (“Alto”) in unlimited personal and commercial projects.

However, the following restrictions apply:

1. You may not resell, sublicense, or redistribute Alto — whether in original or modified form — as a standalone product, hosted service, or software offering.

2. You may not rebrand or present Alto as your own original product. Derivative works must include attribution and must not imply original authorship.

3. The name “Alto”, associated logos, and brand identity may not be used without prior written permission from the copyright holder.

4. Attribution must be preserved in all copies or substantial portions of the Software, including in open-source forks.

5. Contributions are welcome. Unless otherwise agreed in writing, all contributions are licensed back to the project under the terms of this license and ownership remains with the original author.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
