# FeedbackBoard Rails Engine

A mountable Rails engine that replicates core Canny.io-style feedback functionality for your app.

---

## ✅ What Users Can Do

- Visit the feedback board (`/feedback`) with multiple board support
- Submit tickets with title and description across different boards
- Comment on tickets with **dedicated threaded discussions**
- **Navigate to focused thread pages** for in-depth discussions
- Reply to comments with **3-level threading** (Comments → Replies → Nested Replies)
- Upvote tickets and comments (1 vote per user)
- View ticket statuses (`open`, `planned`, `in_progress`, `complete`)
- Search across tickets, descriptions, and comments within boards
- See locked tickets (but cannot comment/vote on them)

---

## 🔒 Permissions & Access

- Easily define which users can:
  - Access the board
  - Submit new tickets
  - Comment or vote
- Recommended: use a method like `current_user.can?(:access_feedback_board)`

---

## 🛠 Features

- Tickets (title, description, status, locked flag)
- Comments (linked to ticket)
- Upvotes (on tickets and comments, per user)
- Configurable statuses (`open`, `planned`, etc.)
- Admin control to lock tickets or change status
- Mountable engine with namespaced models/controllers
- Ready-to-override views with minimal Tailwind styling

---

## 🚀 Usage

Mount in `routes.rb`:

```ruby
mount FeedbackBoard::Engine => "/feedback"
```

### 🎣 **Host App Callback Hooks**

The feedback board automatically calls methods in your host app when events occur. Just define these methods and they'll be called with full context.

## 📁 **Where To Put The Callbacks**

Add these methods to your **host app's main ApplicationController**:

**File:** `app/controllers/application_controller.rb` (in your main app, not the engine)

```ruby
# In your main app's ApplicationController
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

## 📋 **All Available Callback Methods**

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

**Safety Features:**
- ✅ **Error Isolation**: If your callback method fails, it won't break ticket/comment creation
- ✅ **Automatic Detection**: Only calls methods that exist - no configuration needed
- ✅ **Logging**: Callback errors are logged for debugging
- ✅ **Zero Setup**: Just define the methods you want, ignore the ones you don't need

## 🛠 **Setup Instructions**

### Option 1: In ApplicationController (Recommended)
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

### Option 2: In a Concern (For Complex Logic)
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

### Option 3: Dedicated Service Class
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

## 🚀 **Quick Test**

To verify callbacks are working, add this simple test:

```ruby
# In ApplicationController
def ticket_created(ticket, board, user)
  Rails.logger.info "🎫 Callback working! New ticket: #{ticket.title}"
  puts "🎫 Callback working! New ticket: #{ticket.title}"
end
```

Then create a ticket and check your Rails console/logs!

---

## 📋 Implementation Status

### ✅ COMPLETED

#### Backend Core
- [x] **Database Migrations**
  - `feedback_board_tickets` with title, description, status, locked, user_id
  - `feedback_board_comments` with ticket reference, user_id, content
  - `feedback_board_upvotes` with polymorphic references, unique constraints
- [x] **Models & Associations**
  - `FeedbackBoard::Ticket` with validations, scopes, helper methods
  - `FeedbackBoard::Comment` with validations and upvote logic
  - `FeedbackBoard::Upvote` with polymorphic associations
- [x] **Controllers**
  - `ApplicationController` with authentication/authorization framework
  - `TicketsController` with full CRUD operations
  - `CommentsController` for creating/deleting comments
  - `UpvotesController` for voting functionality
- [x] **Routes**
  - Nested resources for tickets → comments → upvotes
  - RESTful routing structure

#### Frontend Core
- [x] **Layout & Styling**
  - Main application layout with Tailwind CSS (nobuild approach)
  - Rails UJS integration via CDN for DELETE method handling
  - Responsive design with modern UI components
  - Navigation header with permission-based buttons
- [x] **Tickets Index Page**
  - Status filtering (all, open, planned, in_progress, complete)
  - Sorting (recent, popular)
  - Upvote buttons with visual feedback
  - Clean ticket cards with status badges
  - Empty state handling

### ✅ COMPLETED

#### Views & Forms
- [x] **Ticket Show Page**
  - Individual ticket view with full description
  - Comments section with threading
  - Upvote functionality for ticket and comments
  - Admin controls for status/lock changes
- [x] **Ticket Forms**
  - New ticket form with title/description
  - Edit ticket form (admin only)
  - Form validation and error handling
- [x] **Comment Forms**
  - Inline comment creation with user name display
  - Comment editing/deletion with proper DELETE method handling
  - Rails UJS integration for seamless delete functionality
  - "Commenting as [username]" indicator for user clarity

#### Enhanced Features
- [x] **Helpers & Utilities**
  - View helpers for common UI patterns
  - Permission helpers for cleaner templates
  - Status badge helpers
  - Upvote button helpers
- [x] **JavaScript Integration**
  - Nobuild approach using CDN-delivered assets
  - Rails UJS via unpkg.com for DELETE method handling
  - Custom JavaScript for upvote functionality
  - Reply form toggling and interaction

### ✅ COMPLETED

#### 🎯 MAJOR FEATURE: Dedicated Comment Threading System ✨ **COMPLETE**
This major UX improvement replaces complex inline forms with clean, focused thread discussions:
- ✅ **Simplified Architecture**: Dedicated thread pages at `/tickets/:id/comments/:comment_id`
- ✅ **Enhanced Navigation**: "View Thread & Reply (X replies)" with activity indicators
- ✅ **Clean User Flow**: Click → Navigate → Reply → Success (no complex JavaScript)
- ✅ **Thread Previews**: Main ticket shows comment previews with reply counts
- ✅ **Smart Redirects**: Context-aware navigation after replies/deletions
- ✅ **Rails Callback Fix**: Proper `before_validation` vs `before_create` for depth setting
- ✅ **3-Level Threading**: Comments → Replies → Nested Replies (depth 0, 1, 2)

- [x] **Advanced Functionality**
  - AJAX voting without page reload (Stimulus controller)
  - Hotwire/Stimulus integration with install generator

#### Configuration & Customization
- [x] **Engine Configuration**
  - Install generator with Stimulus controller copying
  - Configurable user display name methods
  - User model configuration (defaults to "User")
  - Configuration initializer support
- [x] **Integration Helpers**
  - User model integration examples in README
  - Authorization system examples (permission methods)
  - Comprehensive documentation with examples

#### Documentation & Polish
- [x] **Complete Documentation**
  - Comprehensive README with installation guide
  - Configuration examples and customization instructions
  - API documentation for models and routes
  - Troubleshooting section
  - Multiple integration patterns and examples

### ✅ COMPLETED

#### 🎯 MAJOR FEATURE: Multiple Boards System ✨ **COMPLETE**
This major architectural change transforms the feedback system from single-board to multi-board capability:
- ✅ **Complete URL restructure**: `/feedback/boards/:slug/tickets`
- ✅ **Database migration**: All existing tickets preserved under default board
- ✅ **Full admin interface**: Create, edit, delete boards with safety checks
- ✅ **Board-scoped search**: Search works within individual boards
- ✅ **All views updated**: Complete UI overhaul for board context
- ✅ **Permission system**: Board-level access control ready

- [x] **🎯 MAJOR FEATURE: Multiple Boards System**
  - [x] **Database Schema**
    - [x] Create `feedback_board_boards` table (id, name, slug, description, created_at, updated_at)
    - [x] Add `board_id` foreign key to `feedback_board_tickets`
    - [x] Create default 'Feedback' board in migration
    - [x] Add database indexes for performance
  - [x] **Models & Associations**
    - [x] `FeedbackBoard::Board` model with validations (name required, slug uniqueness)
    - [x] Update `FeedbackBoard::Ticket` to belong_to :board
    - [x] Board has_many :tickets, dependent: :restrict_with_error
    - [x] Board slug generation and URL-friendly routing
  - [x] **Routes & Controllers**
    - [x] Update routes to nest tickets under boards: `/feedback/boards/:board_slug/tickets`
    - [x] Add BoardsController for admin board management
    - [x] Update TicketsController to scope by board
    - [x] Update CommentsController and UpvotesController for board context
    - [x] Admin routes for board CRUD operations
  - [x] **Views & UI**
    - [x] Board selection/navigation in main layout
    - [x] Admin board management interface (create, edit, delete boards)
    - [x] Update all ticket views to include board context
    - [x] Board-specific statistics in admin dashboard
    - [x] Breadcrumb navigation for boards -> tickets
  - [x] **Admin Features**
    - [x] Admin can create/edit/delete boards
    - [x] Board-specific permissions (who can access which boards)
    - [x] Default board configuration
    - [x] Board-specific email notification settings
  - [x] **Migration & Backwards Compatibility**
    - [x] Data migration to assign existing tickets to default board
    - [x] Update configuration options for board-specific settings
    - [x] Update documentation and examples

### ✅ RECENT BUG FIXES & IMPROVEMENTS

- [x] **Comment Deletion Fix** *(December 2024)*
  - ✅ Fixed comment delete functionality that was incorrectly sending GET requests
  - ✅ Added Rails UJS via CDN (nobuild approach) to handle `method: :delete` properly
  - ✅ Comments can now be deleted seamlessly with proper confirmation dialogs
  - ✅ Maintained nobuild architecture without asset pipeline dependencies



### ✅ COMPLETED

#### 🎯 MAJOR FEATURE: Host App Callback Hooks ✨ **COMPLETE**
This powerful extensibility feature allows host apps to hook into feedback board events with simple, guessable callback methods:
- ✅ **Simple Callback API**: Just define methods like `ticket_created` in your host app
- ✅ **All Major Events**: Tickets, comments, upvotes creation/deletion/changes
- ✅ **Rich Context Data**: Every callback receives the object, board, user, and relevant context
- ✅ **Error Isolation**: Callback failures don't break the main feedback flow
- ✅ **Zero Configuration**: Host app just defines methods and they get called automatically

- [x] **🎯 MAJOR FEATURE: Host App Callback Hooks**
  - [x] **CallbackManager System**
    - [x] Safe callback execution with error handling
    - [x] Automatic host app method detection
    - [x] Graceful failure handling (logged but doesn't break main flow)
  - [x] **Model Integration**
    - [x] Ticket callbacks: `ticket_created`, `ticket_status_changed`
    - [x] Comment callbacks: `comment_created`, `comment_deleted`
    - [x] Upvote callbacks: `upvote_created`, `upvote_removed`
    - [x] All callbacks include full context (object, board, user)
  - [x] **Host App Integration**
    - [x] Simple method-based API (no configuration needed)
    - [x] Guessable callback names following Rails conventions
    - [x] Rich context data for all integrations (Slack, analytics, etc.)

### 🚧 IN PROGRESS / TODO

- [x] **Advanced Functionality**
  - [x] Search
    - ✅ search tickets by title, description, and comment content
    - ✅ database-agnostic search (PostgreSQL ILIKE / SQLite & MySQL LIKE with LOWER)
    - ✅ integrated with existing filtering and sorting
    - ✅ performance optimizations with database indexes
    - ✅ intuitive search UI with clear results feedback
  - [x] Email notifications system
    - ✅ new comments send emails using the host app's ActionMailer config
    - ✅ can be turned on/off via admin interface
    - ✅ configurable from: email address
    - ✅ when a user submits a ticket, they receive all updates regarding that ticket
    - ✅ admin can configure whether they receive all tickets/comments
    - ✅ beautiful HTML and text email templates
    - ✅ background job processing with deliver_later
    - ✅ admin dashboard with stats and recent activity
    - ✅ persistent database-backed configuration (no more memory-only settings)
  - Advanced filtering and sorting options (recent, popular, date range)

- [ ] **Admin Features**
  - Admin dashboard for ticket management
  - Bulk status updates
  - User management integration
  - Advanced moderation tools

#### Testing & Quality
- [ ] **Test Suite**
  - Model tests with factories
  - Controller tests with authentication
  - Integration tests for user flows
  - JavaScript/Stimulus tests

---

## 🎯 Next Steps

1. **🧪 Testing Suite** - Comprehensive test coverage for comment threading and board functionality
2. **⚡ Real-time Updates** - Turbo Streams for live ticket and comment updates
3. **🔐 Advanced Permissions** - Per-board access control and comment moderation
4. **📧 Board-specific Notifications** - Email settings per board
5. **🎭 Board Customization** - Custom themes, logos, and settings per board
6. **🔍 Enhanced Search** - Full-text search within comment threads
7. **📱 Mobile Optimization** - Responsive design improvements for thread navigation

---

## 🚨 Breaking Changes Notice

### ✅ Multiple Boards Implementation - COMPLETE
**BREAKING CHANGE IMPLEMENTED** - Database migration completed:
- ✅ All existing tickets migrated to default "Feedback" board
- ✅ URL structure updated from `/feedback/tickets` to `/feedback/boards/feedback/tickets`
- ✅ No backwards compatibility (development phase)

### ✅ Migration Completed
1. ✅ Created boards table with default "Feedback" board
2. ✅ Added board_id to tickets table with foreign key constraint
3. ✅ Migrated all existing tickets to default board
4. ✅ Updated all routes and controllers to use board context
5. ✅ Updated all views and navigation for board selection
6. ✅ Fixed permission system delegation issues
