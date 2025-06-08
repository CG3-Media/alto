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
