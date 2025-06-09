# FeedbackBoard Rails Engine

A mountable Rails engine that replicates core Canny.io-style feedback functionality for your app. Users can submit tickets across multiple boards, engage in threaded discussions, vote on content, and admins can manage status and moderation.

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.0%2B-red.svg)](https://rubyonrails.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](MIT-LICENSE)

## ✨ Features

- 📋 **Multiple Boards** - Create and manage multiple feedback boards (Feature, Bug Reports, etc.)
- 🎫 **Ticket Management** - Create, view, and manage feedback tickets within boards
- 💬 **Threaded Comments** - Dedicated discussion pages for comment threads with nested replies (3 levels deep)
- 👍 **Upvoting** - Users can vote on tickets and comments (with built-in AJAX - no setup required!)
- 🔍 **Search** - Full-text search across ticket titles, descriptions, and comments (board-scoped)
- 📧 **Email Notifications** - Configurable email alerts for tickets, comments, and status changes
- 🎣 **Callback Hooks** - Simple callback methods to integrate with Slack, analytics, external APIs, and more
- 📊 **Status Tracking** - `open`, `planned`, `in_progress`, `complete`
- 🔒 **Moderation** - Lock tickets to prevent further discussion
- 👑 **Admin Dashboard** - Statistics, recent activity, board management, and email configuration
- 🎨 **Beautiful UI** - Clean Tailwind CSS design with user-friendly forms
- 🔐 **Permissions** - Flexible permission system with board-level access control
- ⚡ **Performance** - Optimized queries and database indexes
- 🚀 **Zero Setup** - All JavaScript functionality works immediately after mounting the engine
- 🗄️ **Controlled Database Setup** - Use the install generator to set up database tables safely

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'feedback_board'
```

And then execute:
```bash
bundle install
```

## ⚙️ Setup

### 1. Add routes
Add to your `config/routes.rb`:
```ruby
mount FeedbackBoard::Engine => "/feedback"
```

### 2. Run the installer
```bash
rails generate feedback_board:install
```

**🎯 The install generator is completely idempotent and handles everything:**

- ✅ **Checks existing state** - Won't recreate what already exists
- ✅ **Database tables** - Creates missing tables, skips existing ones
- ✅ **Configuration** - Creates initializer only if it doesn't exist
- ✅ **Default boards** - Only offers to create if no boards exist
- ✅ **Status summary** - Shows you exactly what's configured vs missing
- ✅ **Safe to re-run** - Run it as many times as you want!

**That's it!** ✨

**🎯 Smart Database Setup**: The install generator creates all required database tables for you - no separate migrations needed!

**✨ AJAX voting functionality is included and works automatically - no JavaScript setup required!**

### 3. (Optional) Customize configuration

The engine works immediately with smart defaults. **The install generator creates a comprehensive configuration file** at `config/initializers/feedback_board.rb` with all available options and examples.

```ruby
# config/initializers/feedback_board.rb (created by generator)
FeedbackBoard.configure do |config|
  # All configuration options with examples and documentation!
  # Just uncomment and customize what you need.

  # Example: Restrict access to signed-in users only
  config.permission :can_access_feedback_board? do
    user_signed_in?
  end

  # Example: Only admins can edit tickets
  config.permission :can_edit_tickets? do
    current_user&.admin?
  end

  # ... many more options with full documentation
end
```

**📖 Check the generated initializer for all available options and examples!**

## 🗑️ Uninstallation

Need to remove FeedbackBoard? We've got you covered! ✋

### Quick Uninstall
```bash
rails generate feedback_board:uninstall
```

**🔐 Safe & Interactive**: The uninstall generator will:
- ⚠️  Show data loss warnings and ask for confirmation
- 🗑️  Remove the initializer file automatically
- 🗄️  Optionally create a database cleanup migration
- 🛤️  Provide instructions for route removal
- 📋  Guide you through final cleanup steps
- 💾  Offer to open your routes file for editing

### What Gets Removed
- ✅ Configuration file (`config/initializers/feedback_board.rb`)
- ✅ Database tables (optional - with confirmation)
  - `feedback_board_admin_settings`
  - `feedback_board_boards`
  - `feedback_board_status_sets`
  - `feedback_board_statuses`
  - `feedback_board_status_transitions`
  - `feedback_board_tickets`
  - `feedback_board_comments`
  - `feedback_board_upvotes`

### Manual Steps
The generator will guide you to manually remove:
1. **Routes**: `mount FeedbackBoard::Engine => "/feedback"`
2. **Gemfile**: `gem 'feedback_board'`
3. **Bundle**: Run `bundle install`
4. **Custom overrides** (if any): Views, styles, callback methods

**💡 Pro Tip**: The generator asks before doing anything destructive and provides clear instructions for each step!

## 🔐 Permissions System

**Zero configuration required!** The engine works out of the box with sensible defaults.

**The install generator creates a comprehensive initializer** at `config/initializers/feedback_board.rb` with all permission options pre-configured and documented. Simply uncomment and customize the permissions you want to change.

**Smart defaults provided for everything** - the engine handles authentication gracefully whether you're using Devise, custom auth, or no authentication at all.

## 📱 Usage Examples

### Basic Integration

```erb
<!-- In your app's navigation -->
<%= link_to "Feedback", feedback_board.root_path, class: "nav-link" %>

<!-- Link to specific board -->
<%= link_to "Feature Requests", feedback_board.board_path("features"), class: "nav-link" %>
<%= link_to "Bug Reports", feedback_board.board_path("bugs"), class: "nav-link" %>

<!-- Or embed directly -->
<iframe src="/feedback" width="100%" height="600"></iframe>
```

### Multiple Boards

```erb
<!-- List all boards -->
<% FeedbackBoard::Board.all.each do |board| %>
  <%= link_to board.name, feedback_board.board_path(board.slug),
      class: "block p-4 border rounded hover:bg-gray-50" %>
<% end %>

<!-- Board-specific ticket creation -->
<%= link_to "Submit Feature Request",
    feedback_board.new_board_ticket_path("features"),
    class: "btn btn-primary" %>
```

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
