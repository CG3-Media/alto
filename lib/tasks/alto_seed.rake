namespace :alto do
  desc "Create seed data for Alto development"
  task seed_dev: :environment do
    puts "🌱 Seeding Alto with development data..."
    puts ""

    begin
      # Check if user model exists
      user_model_class = nil
      begin
        user_model_class = ::Alto.configuration.user_model.constantize
        puts "👤 Using user model: #{user_model_class.name}"
      rescue NameError
        puts "⚠️  No user model found (#{::Alto.configuration.user_model})"
        puts "   Creating data without user associations..."
      end

      # Create sample users if user model exists
      sample_users = []
      if user_model_class
        sample_users = create_sample_users(user_model_class)
        puts "✅ Created #{sample_users.length} sample users (password: 'password')"
      end

      # Create status sets and statuses
      status_data = create_status_sets_and_statuses
      puts "✅ Created #{status_data[:status_sets].length} status sets with #{status_data[:all_statuses].length} statuses"

      # Create boards
      boards = create_sample_boards(status_data[:status_sets])
      puts "✅ Created #{boards.length} boards"

      # Create tickets
      tickets = create_sample_tickets(boards, sample_users, status_data[:statuses])
      puts "✅ Created #{tickets.length} tickets across all boards"

      # Create comments with threading
      comments = create_sample_comments(tickets, sample_users)
      puts "✅ Created #{comments.length} comments with realistic threading"

      # Create upvotes
      upvotes = create_sample_upvotes(tickets, comments, sample_users)
      puts "✅ Created #{upvotes.length} upvotes on tickets and comments"

      puts ""
      puts "🎉 Seed data creation completed successfully!"
      puts ""
      puts "📊 Summary:"
      puts "   • #{boards.length} boards with different themes"
      puts "   • #{tickets.length} tickets with varied content"
      puts "   • #{comments.length} comments with threading (up to 3 levels)"
      puts "   • #{upvotes.length} upvotes distributed across content"
      puts ""
      puts "🚀 Visit /feedback to explore your seeded data!"

    rescue => e
      puts "❌ Failed to create seed data:"
      puts "   #{e.message}"
      puts "   #{e.backtrace.first}"
      exit 1
    end
  end

  desc "Clear all Alto data without confirmation (alias for clear_dev_data)"
  task clear: :clear_dev_data

  desc "Clear all Alto development data (WARNING: No confirmation prompt)"
  task clear_dev_data: :environment do
    puts "🗑️  Clearing Alto development data..."
    puts "⚠️  Removing ALL Alto data without confirmation..."
    puts ""

    # Delete in proper order to avoid foreign key constraints
    upvotes_count = Alto::Upvote.destroy_all.length
    comments_count = Alto::Comment.destroy_all.length
    tickets_count = Alto::Ticket.destroy_all.length
    boards_count = Alto::Board.destroy_all.length
    statuses_count = Alto::Status.destroy_all.length
    status_sets_count = Alto::StatusSet.destroy_all.length

    puts "✅ Cleared all data:"
    puts "   • #{upvotes_count} upvotes"
    puts "   • #{comments_count} comments"
    puts "   • #{tickets_count} tickets"
    puts "   • #{boards_count} boards"
    puts "   • #{statuses_count} statuses"
    puts "   • #{status_sets_count} status sets"
  end

private

  def create_sample_users(user_model_class)
    return [] unless user_model_class

    users = []
    sample_user_data = [
      { email: 'admin@example.com', name: 'Admin User' },
      { email: 'developer@example.com', name: 'Jane Developer' },
      { email: 'product@example.com', name: 'Product Manager' },
      { email: 'user1@example.com', name: 'Alice Johnson' },
      { email: 'user2@example.com', name: 'Bob Smith' },
      { email: 'user3@example.com', name: 'Charlie Brown' },
      { email: 'tester@example.com', name: 'QA Tester' },
      { email: 'designer@example.com', name: 'UI Designer' }
    ]

    sample_user_data.each do |user_data|
      # Try to find existing user first
      existing_user = user_model_class.find_by(email: user_data[:email])

      if existing_user
        users << existing_user
      else
        # Create user with attributes that most user models support
        user_attrs = { email: user_data[:email] }
        user_attrs[:name] = user_data[:name] if user_model_class.column_names.include?('name')

        # Add password fields if user model supports them (Devise, etc.)
        if user_model_class.column_names.include?('encrypted_password') || user_model_class.column_names.include?('password_digest')
          user_attrs[:password] = 'password'
          user_attrs[:password_confirmation] = 'password' if user_model_class.column_names.include?('password_confirmation')
        end

        begin
          user = user_model_class.create!(user_attrs)
          users << user
        rescue => e
          puts "⚠️  Could not create user #{user_data[:email]}: #{e.message}"
        end
      end
    end

    users
  end

  def create_status_sets_and_statuses
    status_sets = []
    all_statuses = []
    statuses = {}

    # Bug Tracking Status Set
    bug_status_set = Alto::StatusSet.find_or_create_by!(name: 'Bug Workflow') do |ss|
      ss.description = 'Status workflow for bug reports and issues'
      ss.is_default = false
    end

    bug_status_data = [
      { name: 'New', slug: 'new', color: 'blue', position: 1 },
      { name: 'Triaged', slug: 'triaged', color: 'yellow', position: 2 },
      { name: 'In Progress', slug: 'in_progress', color: 'purple', position: 3 },
      { name: 'Testing', slug: 'testing', color: 'orange', position: 4 },
      { name: 'Fixed', slug: 'fixed', color: 'green', position: 5 },
      { name: 'Won\'t Fix', slug: 'wont_fix', color: 'gray', position: 6 }
    ]

    statuses[:bug] = {}
    bug_status_data.each do |status_data|
      status = bug_status_set.statuses.create!(
        name: status_data[:name],
        color: status_data[:color],
        position: status_data[:position]
      )
      statuses[:bug][status_data[:slug].to_sym] = status
      all_statuses << status
    end

    status_sets << bug_status_set

    # Feature Request Status Set
    feature_status_set = Alto::StatusSet.find_or_create_by!(name: 'Feature Workflow') do |ss|
      ss.description = 'Status workflow for feature requests and enhancements'
      ss.is_default = true
    end

    feature_status_data = [
      { name: 'Proposed', slug: 'proposed', color: 'blue', position: 1 },
      { name: 'Under Review', slug: 'under_review', color: 'yellow', position: 2 },
      { name: 'Approved', slug: 'approved', color: 'purple', position: 3 },
      { name: 'In Development', slug: 'in_development', color: 'orange', position: 4 },
      { name: 'Released', slug: 'released', color: 'green', position: 5 },
      { name: 'Rejected', slug: 'rejected', color: 'red', position: 6 }
    ]

    statuses[:feature] = {}
    feature_status_data.each do |status_data|
      status = feature_status_set.statuses.create!(
        name: status_data[:name],
        color: status_data[:color],
        position: status_data[:position]
      )
      statuses[:feature][status_data[:slug].to_sym] = status
      all_statuses << status
    end

    status_sets << feature_status_set

    {
      status_sets: status_sets,
      all_statuses: all_statuses,
      statuses: statuses
    }
  end

  def create_sample_boards(status_sets)
    boards = []

    board_data = [
      {
        name: 'Bug Reports',
        slug: 'bugs',
        description: 'Report bugs and technical issues here. Help us improve the application by describing problems you encounter.',
        item_label_singular: 'bug report',
        status_set: status_sets.find { |s| s.name == 'Bug Workflow' },
        is_admin_only: false
      },
      {
        name: 'Feature Requests',
        slug: 'features',
        description: 'Suggest new features and enhancements. Share your ideas to make our product better!',
        item_label_singular: 'feature request',
        status_set: status_sets.find { |s| s.name == 'Feature Workflow' },
        is_admin_only: false
      },
      {
        name: 'General Feedback',
        slug: 'feedback',
        description: 'Share general thoughts, suggestions, and feedback about your experience.',
        item_label_singular: 'feedback',
        status_set: status_sets.find { |s| s.name == 'Feature Workflow' },
        is_admin_only: false
      },
      {
        name: 'Internal Issues',
        slug: 'internal',
        description: 'Internal team discussions and administrative items.',
        item_label_singular: 'issue',
        status_set: status_sets.find { |s| s.name == 'Bug Workflow' },
        is_admin_only: true
      }
    ]

    board_data.each do |data|
      board = Alto::Board.find_or_create_by!(slug: data[:slug]) do |b|
        b.name = data[:name]
        b.description = data[:description]
        b.item_label_singular = data[:item_label_singular]
        b.status_set = data[:status_set]
        b.is_admin_only = data[:is_admin_only]
      end
      boards << board
    end

    boards
  end

  def create_sample_tickets(boards, sample_users, statuses)
    tickets = []

    # Bug Reports
    bugs_board = boards.find { |b| b.name == 'Bug Reports' }

    bug_tickets = [
      {
        title: 'Login button not working on mobile Safari',
        description: "When I try to log in using Safari on iPhone, the login button doesn't respond to taps. Works fine on Chrome and other browsers.\n\nSteps to reproduce:\n1. Open app in Safari on iPhone\n2. Go to login page\n3. Tap login button\n4. Nothing happens\n\nExpected: Should log me in\nActual: Button doesn't respond",
        status_slug: statuses[:bug][:new].slug
      },
      {
        title: 'Dashboard loading very slowly',
        description: "The main dashboard takes 15-20 seconds to load, which feels way too slow. Other pages load quickly, but the dashboard specifically has performance issues.\n\nI'm on a decent internet connection (100mbps) so it's not a network issue on my end.",
        status_slug: statuses[:bug][:triaged].slug
      },
      {
        title: 'Email notifications not being sent',
        description: "I've enabled email notifications in my settings, but I'm not receiving any emails when there are updates to tickets I'm following.\n\nChecked spam folder - nothing there either.",
        status_slug: statuses[:bug][:in_progress].slug
      },
      {
        title: 'Search results showing deleted items',
        description: "When I search for tickets, the results include items that have been deleted. Clicking on them shows a 404 error.\n\nThe search index probably isn't being updated when items are deleted.",
        status_slug: statuses[:bug][:testing].slug
      },
      {
        title: 'File upload breaks with large images',
        description: "Trying to upload images larger than 2MB causes the upload to fail with a generic error message. Would be nice to have:\n\n1. Better error message\n2. Image compression\n3. Progress indicator",
        status_slug: statuses[:bug][:fixed].slug
      }
    ]

    bug_tickets.each do |ticket_data|
      user = sample_users.sample || nil
      ticket = Alto::Ticket.create!(
        title: ticket_data[:title],
        description: ticket_data[:description],
        board: bugs_board,
        user: user,
        status_slug: ticket_data[:status_slug],
        created_at: rand(30.days).seconds.ago
      )
      tickets << ticket
    end

        # Feature Requests
    features_board = boards.find { |b| b.name == 'Feature Requests' }
    feature_tickets = [
      {
        title: 'Dark mode support',
        description: "It would be great to have a dark mode option in the user preferences. Many modern applications offer this and it's easier on the eyes, especially during evening work sessions.\n\nCould include:\n- Toggle in user settings\n- System preference detection\n- Smooth transition between modes",
        status_slug: statuses[:feature][:proposed].slug
      },
      {
        title: 'Bulk actions for ticket management',
        description: "As an admin, I often need to update multiple tickets at once. It would be helpful to have bulk actions like:\n\n- Change status of multiple tickets\n- Assign multiple tickets to a user\n- Add tags to multiple tickets\n- Delete multiple tickets\n\nCheckboxes next to each ticket with an actions dropdown would work well.",
        status_slug: statuses[:feature][:under_review].slug
      },
      {
        title: 'Advanced search and filtering',
        description: "The current search is pretty basic. Would love to see:\n\n- Filter by date range\n- Filter by user/author\n- Filter by tags\n- Filter by status\n- Saved search queries\n- Search within comments too\n\nBasically make it easier to find specific tickets in large boards.",
        status_slug: statuses[:feature][:approved].slug
      },
      {
        title: 'Mobile app',
        description: "A native mobile app would be amazing! The web version works on mobile but a dedicated app would provide:\n\n- Push notifications\n- Better offline support\n- Native sharing\n- Camera integration for screenshots\n- Faster navigation",
        status_slug: statuses[:feature][:in_development].slug
      },
      {
        title: 'Integration with Slack',
        description: "Slack integration would be super useful for teams. Features could include:\n\n- Notifications in Slack channels when tickets are created/updated\n- Ability to create tickets from Slack\n- Link previews for ticket URLs\n- Commands like /ticket-status\n\nThis was requested by our whole team!",
        status_slug: statuses[:feature][:released].slug
      },
      {
        title: 'AI-powered ticket categorization',
        description: "Using machine learning to automatically categorize and tag tickets based on their content. This could help with:\n\n- Auto-assigning to the right team\n- Detecting duplicate tickets\n- Suggesting similar existing tickets\n- Priority scoring\n\nProbably too ambitious for now but would be cool in the future.",
        status_slug: statuses[:feature][:rejected].slug
      }
    ]

    feature_tickets.each do |ticket_data|
      user = sample_users.sample
      ticket = Alto::Ticket.create!(
        title: ticket_data[:title],
        description: ticket_data[:description],
        board: features_board,
        user: user,
        status_slug: ticket_data[:status_slug],
        created_at: rand(45.days).seconds.ago
      )
      tickets << ticket
    end

    # General Feedback
    feedback_board = boards.find { |b| b.name == 'General Feedback' }
    feedback_tickets = [
      {
        title: 'Love the new interface design!',
        description: "Just wanted to say the recent UI update looks fantastic. Much cleaner and more intuitive than before. Great job on the visual refresh!"
      },
      {
        title: 'Suggestion: keyboard shortcuts',
        description: "It would be nice to have keyboard shortcuts for common actions like creating a new ticket (maybe Ctrl+N), searching (Ctrl+K), etc. Would speed up workflow for power users."
      },
      {
        title: 'Documentation could be better',
        description: "The help docs are a bit sparse. More examples and screenshots would be helpful, especially for the admin features."
      },
      {
        title: 'Great customer support experience',
        description: "Had an issue last week and the support team was super responsive and helpful. Really appreciate the quick turnaround!"
      }
    ]

    feedback_tickets.each do |ticket_data|
      user = sample_users.sample
      ticket = Alto::Ticket.create!(
        title: ticket_data[:title],
        description: ticket_data[:description],
        board: feedback_board,
        user: user,
        created_at: rand(20.days).seconds.ago
      )
      tickets << ticket
    end

    # Internal Issues (admin only)
    internal_board = boards.find { |b| b.name == 'Internal Issues' }
    internal_tickets = [
      {
        title: 'Server migration planning',
        description: "Need to plan the migration to the new server infrastructure. Key considerations:\n\n- Downtime minimization\n- Data backup strategy\n- Performance testing\n- Rollback plan",
        status_slug: statuses[:bug][:new].slug
      },
      {
        title: 'Update security dependencies',
        description: "Several security vulnerabilities reported in our dependencies. Need to update:\n\n- Rails to latest patch version\n- jQuery to address XSS issues\n- Update SSL certificates\n\nSchedule for maintenance window.",
        status_slug: statuses[:bug][:in_progress].slug
      }
    ]

    internal_tickets.each do |ticket_data|
      user = sample_users.sample
      ticket = Alto::Ticket.create!(
        title: ticket_data[:title],
        description: ticket_data[:description],
        board: internal_board,
        user: user,
        status_slug: ticket_data[:status_slug],
        created_at: rand(7.days).seconds.ago
      )
      tickets << ticket
    end

    tickets
  end

  def create_sample_comments(tickets, sample_users)
    comments = []
    return comments if sample_users.empty?

    # Create varied comment scenarios on different tickets
    tickets.each_with_index do |ticket, index|
      # Not every ticket needs comments
      next if index % 3 == 0

      comment_scenarios = [
        # Simple question and answer
        [
          "Can you provide more details about when this happens?",
          "Sure! It happens every time I try to access the dashboard around 9 AM when traffic is highest."
        ],
        # Multiple people discussing
        [
          "I'm seeing the same issue on my end. Chrome on Windows 10.",
          "Interesting - I'm on Mac and haven't seen this. Might be OS specific?",
          "Could be a browser caching issue. Have you tried clearing cache?"
        ],
        # Status update conversation
        [
          "We've reproduced this issue and identified the root cause. Working on a fix now.",
          "Great! Any estimate on when this might be resolved?",
          "Should have a fix deployed by end of week. Will update here when it's live."
        ],
        # Feature discussion
        [
          "This would be incredibly useful for our team workflow!",
          "Agreed! We've been asking for something like this for months.",
          "What's the timeline looking like for this feature?",
          "We're planning to include this in the Q2 roadmap. Will post updates as we progress."
        ]
      ]

      scenario = comment_scenarios.sample

      scenario.each_with_index do |content, comment_index|
        user = sample_users.sample

        # Create top-level comment
        if comment_index == 0
          parent_comment = Alto::Comment.create!(
            content: content,
            ticket: ticket,
            user: user,
            created_at: rand(10.days).seconds.ago
          )
          comments << parent_comment
        else
          # Create replies (some as direct replies, some as nested)
          if comment_index == 1 && comments.last&.ticket == ticket
            # Reply to the previous comment
            reply = Alto::Comment.create!(
              content: content,
              ticket: ticket,
              user: user,
              parent: comments.last,
              created_at: comments.last.created_at + rand(3.days).seconds
            )
            comments << reply
          elsif comment_index >= 2 && comments.length >= 2
            # Create nested reply (depth 2)
            parent_reply = comments.select { |c| c.ticket == ticket && c.depth == 1 }.last
            if parent_reply
              nested_reply = Alto::Comment.create!(
                content: content,
                ticket: ticket,
                user: user,
                parent: parent_reply,
                created_at: parent_reply.created_at + rand(2.days).seconds
              )
              comments << nested_reply
            end
          end
        end
      end
    end

    # Add some standalone comments on tickets that didn't get scenario comments
    standalone_comments = [
      "Thanks for reporting this!",
      "I can confirm this is happening for me too.",
      "Workaround: if you refresh the page it usually works.",
      "This is a duplicate of ticket #123",
      "Fixed in the latest update. Please try again and let us know!",
      "Moving this to the development backlog.",
      "Great suggestion! We'll consider this for the next release.",
      "Could you provide screenshots to help us understand the issue better?",
      "This is working as intended, but I understand the confusion. Let me explain...",
      "We've added this to our high-priority list based on user feedback."
    ]

    tickets.sample(tickets.length / 3).each do |ticket|
      next if comments.any? { |c| c.ticket == ticket }

      user = sample_users.sample
      comment = Alto::Comment.create!(
        content: standalone_comments.sample,
        ticket: ticket,
        user: user,
        created_at: rand(5.days).seconds.ago
      )
      comments << comment
    end

    comments
  end

  def create_sample_upvotes(tickets, comments, sample_users)
    upvotes = []
    return upvotes if sample_users.empty?

    # Create realistic upvote patterns
    # More popular tickets get more upvotes
    tickets.each_with_index do |ticket, index|
      # Determine popularity based on ticket type and age
      popularity_factor = case ticket.board.name
      when 'Bug Reports'
        # Bug reports get moderate upvotes
        rand(1..8)
      when 'Feature Requests'
        # Feature requests can be very popular
        case ticket.status_slug
        when 'approved', 'in_development', 'released'
          rand(5..15)
        when 'proposed', 'under_review'
          rand(2..10)
        else
          rand(1..5)
        end
      when 'General Feedback'
        # General feedback gets fewer upvotes
        rand(1..6)
      else
        rand(1..4)
      end

      # Create upvotes from random users
      upvote_count = [popularity_factor, sample_users.length].min
      upvoting_users = sample_users.sample(upvote_count)

      upvoting_users.each do |user|
        begin
          upvote = Alto::Upvote.create!(
            upvotable: ticket,
            user: user,
            created_at: ticket.created_at + rand(10.days).seconds
          )
          upvotes << upvote
        rescue ActiveRecord::RecordInvalid => e
          # Skip duplicates (user already upvoted this ticket)
        end
      end
    end

    # Upvote some comments too (but fewer than tickets)
    comments.sample(comments.length / 2).each do |comment|
      upvote_count = rand(1..4)
      upvoting_users = sample_users.sample(upvote_count)

      upvoting_users.each do |user|
        begin
          upvote = Alto::Upvote.create!(
            upvotable: comment,
            user: user,
            created_at: comment.created_at + rand(3.days).seconds
          )
          upvotes << upvote
        rescue ActiveRecord::RecordInvalid => e
          # Skip duplicates
        end
      end
    end

    upvotes
  end
end
