# FeedbackBoard Rails Engine

A mountable Rails engine that replicates core Canny.io-style feedback functionality for your app.

---

## ✅ What Users Can Do

- Visit the feedback board (`/feedback`)
- Submit a ticket with a title and description
- Comment on any ticket
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

### 🚧 IN PROGRESS / TODO

#### Views & Forms
- [ ] **Ticket Show Page**
  - Individual ticket view with full description
  - Comments section with threading
  - Upvote functionality for ticket and comments
  - Admin controls for status/lock changes
- [ ] **Ticket Forms**
  - New ticket form with title/description
  - Edit ticket form (admin only)
  - Form validation and error handling
- [ ] **Comment Forms**
  - Inline comment creation
  - Comment editing/deletion

#### Enhanced Features
- [ ] **Helpers & Utilities**
  - View helpers for common UI patterns
  - Permission helpers for cleaner templates
  - Status badge helpers
- [ ] **Advanced Functionality**
  - AJAX voting without page reload
  - Real-time comment updates
  - Email notifications
  - Search functionality
- [ ] **Admin Features**
  - Admin dashboard for ticket management
  - Bulk status updates
  - User management integration

#### Testing & Documentation
- [ ] **Test Suite**
  - Model tests with factories
  - Controller tests with authentication
  - Integration tests for user flows
- [ ] **Documentation**
  - Installation guide
  - Configuration examples
  - Customization instructions
  - API documentation

#### Configuration & Customization
- [ ] **Engine Configuration**
  - Configurable permission methods
  - Customizable status options
  - Theme/styling overrides
- [ ] **Integration Helpers**
  - User model integration examples
  - Authorization system examples
  - Notification system hooks

---

## 🎯 Next Steps

1. **Complete Core Views** - Ticket show page and forms
2. **Add AJAX Functionality** - Smooth voting and commenting
3. **Implement Admin Features** - Status management and moderation
4. **Write Tests** - Comprehensive test coverage
5. **Documentation** - Installation and usage guides
