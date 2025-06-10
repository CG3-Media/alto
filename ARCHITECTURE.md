# FeedbackBoard Engine Architecture

## Polymorphic User Association System

### Overview

FeedbackBoard uses Rails polymorphic associations to provide flexible user model integration. This design allows host applications to use any user model name while maintaining referential integrity and supporting multi-tenant scenarios.

### Database Schema

The polymorphic user pattern is implemented across three core tables:

```sql
-- feedback_board_tickets
user_type VARCHAR NOT NULL  -- e.g., "User", "Account", "Member"
user_id   INTEGER NOT NULL  -- Foreign key to the user record

-- feedback_board_comments
user_type VARCHAR           -- Optional for anonymous comments
user_id   INTEGER          -- Foreign key to the user record

-- feedback_board_upvotes
user_type VARCHAR NOT NULL  -- e.g., "User", "Account", "Member"
user_id   INTEGER NOT NULL  -- Foreign key to the user record
```

### Model Implementation

Each model that references users implements the polymorphic association:

```ruby
class Ticket < ApplicationRecord
  belongs_to :user, polymorphic: true
  before_validation :set_user_type, if: -> { user_id.present? && user_type.blank? }

  private

  def set_user_type
    self.user_type = ::FeedbackBoard.configuration.user_model if user_id.present?
  end
end
```

### Configuration Integration

The `user_type` value is automatically set based on the configuration:

```ruby
# config/initializers/feedback_board.rb
FeedbackBoard.configure do |config|
  config.user_model = "Account"  # This becomes the user_type value
end

# When creating records:
ticket = Ticket.create!(title: "Bug", user: current_account)
# → Automatically sets: user_type = "Account", user_id = current_account.id
```

### Benefits

1. **Host App Flexibility**: Works with any user model name
2. **Multi-Tenant Support**: Multiple user types in same database
3. **Database Integrity**: Proper foreign key relationships
4. **Backwards Compatibility**: Graceful handling of existing data

### Testing Considerations

Engine tests require proper route configuration:

```ruby
class TicketsControllerTest < ActionController::TestCase
  def setup
    @routes = ::FeedbackBoard::Engine.routes  # Required for engine route testing
    # ... rest of setup
  end
end
```

### Migration Safety

All migrations use idempotent patterns with `if_not_exists: true` to support:
- Multiple install/uninstall cycles
- Production deployments and rollbacks
- CI/CD pipeline safety
- Host app migration conflicts

### Error Handling

Common issues and solutions:

1. **"user_type violates not-null constraint"**
   - Cause: Missing polymorphic associations or callbacks
   - Fix: Ensure `belongs_to :user, polymorphic: true` and `set_user_type` callback

2. **Route generation errors in tests**
   - Cause: Missing engine routes in test setup
   - Fix: Add `@routes = ::FeedbackBoard::Engine.routes` to test setup

3. **View rendering errors with current_user**
   - Cause: View templates expecting controller helpers in test environment
   - Fix: Mock current_user method or render without layout in tests

### Future Considerations

- Support for user-less tickets (anonymous feedback)
- Enhanced multi-tenant user scoping
- User model polymorphic caching strategies
- Cross-tenant user type migrations
