# FeedbackBoard Rails Engine

A mountable Rails engine that replicates core Canny.io-style feedback functionality for your app.

---

## ✅ What Users Can Do

- Visit the feedback board (`/feedback`)
- Submit a ticket with a title and description
- Comment on any ticket (with username display in comment form)
- Upvote tickets and comments (1 vote per user)
- View ticket statuses (`open`, `planned`, `in_progress`, `complete`)
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
  - Main application layout with Tailwind CSS
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
  - Comment editing/deletion (via controllers)
  - "Commenting as [username]" indicator for user clarity

#### Enhanced Features
- [x] **Helpers & Utilities**
  - View helpers for common UI patterns
  - Permission helpers for cleaner templates
  - Status badge helpers
  - Upvote button helpers

### ✅ COMPLETED
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

1. **🧪 Testing Suite** - Comprehensive test coverage for the new board functionality
2. **🎨 Board Views** - Create dedicated board listing and board management views
3. **⚡ Real-time Updates** - Turbo Streams for live ticket and comment updates
4. **🔐 Advanced Permissions** - Per-board access control and moderation
5. **📧 Board-specific Notifications** - Email settings per board
6. **🎭 Board Customization** - Custom themes, logos, and settings per board

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
