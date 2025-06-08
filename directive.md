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

1. **Advanced Features** - Real-time updates with Turbo Streams
2. **Admin Dashboard** - Centralized ticket management interface
3. **Testing Suite** - Comprehensive test coverage
4. **Enhanced Search** - Full-text search across tickets and comments
5. **Email Notifications** - Configurable notification system
