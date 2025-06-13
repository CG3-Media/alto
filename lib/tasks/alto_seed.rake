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
        puts "✅ Created #{sample_users.length} sample users with secure random passwords"
      end

      # Create status sets and statuses
      status_data = create_status_sets_and_statuses
      puts "✅ Created #{status_data[:status_sets].length} status sets with #{status_data[:all_statuses].length} statuses"

      # Create boards
      boards = create_sample_boards(status_data[:status_sets])
      puts "✅ Created #{boards.length} boards"

      # Create custom fields for boards
      fields = create_custom_fields(boards)
      puts "✅ Created #{fields.length} custom fields across boards"

      # Create tags for boards
      tags = create_sample_tags(boards)
      puts "✅ Created #{tags.length} tags across all boards"

      # Create tickets
      tickets = create_sample_tickets(boards, sample_users, status_data[:statuses])
      puts "✅ Created #{tickets.length} tickets across all boards"

      # Create tag assignments
      taggings = create_sample_taggings(tickets, tags)
      puts "✅ Created #{taggings.length} tag assignments for tickets"

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
      puts "   • #{fields.length} custom fields across Bug Reports and Feature Requests"
      puts "   • #{tags.length} tags with realistic colors and categories"
      puts "   • #{tickets.length} tickets with varied content and field values"
      puts "   • #{taggings.length} tag assignments showing realistic usage patterns"
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
    taggings_count = Alto::Tagging.destroy_all.length
    tags_count = Alto::Tag.destroy_all.length
    tickets_count = Alto::Ticket.destroy_all.length
    boards_count = Alto::Board.destroy_all.length
    statuses_count = Alto::Status.destroy_all.length
    status_sets_count = Alto::StatusSet.destroy_all.length

    puts "✅ Cleared all data:"
    puts "   • #{upvotes_count} upvotes"
    puts "   • #{comments_count} comments"
    puts "   • #{taggings_count} taggings"
    puts "   • #{tags_count} tags"
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
      { email: "admin@example.com", name: "Admin User" },
      { email: "developer@example.com", name: "Jane Developer" },
      { email: "product@example.com", name: "Product Manager" },
      { email: "user1@example.com", name: "Alice Johnson" },
      { email: "user2@example.com", name: "Bob Smith" },
      { email: "user3@example.com", name: "Charlie Brown" },
      { email: "tester@example.com", name: "QA Tester" },
      { email: "designer@example.com", name: "UI Designer" }
    ]

    sample_user_data.each do |user_data|
      # Try to find existing user first
      existing_user = user_model_class.find_by(email: user_data[:email])

      if existing_user
        users << existing_user
      else
        # Create user with attributes that most user models support
        user_attrs = { email: user_data[:email] }
        user_attrs[:name] = user_data[:name] if user_model_class.column_names.include?("name")

        # Add password fields if user model supports them (Devise, etc.)
        if user_model_class.column_names.include?("encrypted_password") || user_model_class.column_names.include?("password_digest")
          # Generate secure random password to avoid "password has been breached" errors
          secure_password = SecureRandom.alphanumeric(12)
          user_attrs[:password] = secure_password
          user_attrs[:password_confirmation] = secure_password if user_model_class.column_names.include?("password_confirmation")
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
    bug_status_set = Alto::StatusSet.find_or_create_by!(name: "Bug Workflow") do |ss|
      ss.description = "Status workflow for bug reports and issues"
      ss.is_default = false
    end

    bug_status_data = [
      { name: "New", slug: "new", color: "blue", position: 1 },
      { name: "Triaged", slug: "triaged", color: "yellow", position: 2 },
      { name: "In Progress", slug: "in_progress", color: "purple", position: 3 },
      { name: "Testing", slug: "testing", color: "orange", position: 4 },
      { name: "Fixed", slug: "fixed", color: "green", position: 5 },
      { name: "Won't Fix", slug: "wont_fix", color: "gray", position: 6 }
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
    feature_status_set = Alto::StatusSet.find_or_create_by!(name: "Feature Workflow") do |ss|
      ss.description = "Status workflow for feature requests and enhancements"
      ss.is_default = true
    end

    feature_status_data = [
      { name: "Proposed", slug: "proposed", color: "blue", position: 1 },
      { name: "Under Review", slug: "under_review", color: "yellow", position: 2 },
      { name: "Approved", slug: "approved", color: "purple", position: 3 },
      { name: "In Development", slug: "in_development", color: "orange", position: 4 },
      { name: "Released", slug: "released", color: "green", position: 5 },
      { name: "Rejected", slug: "rejected", color: "red", position: 6 }
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
        name: "Bug Reports",
        slug: "bugs",
        description: "Report bugs and technical issues here. Help us improve the application by describing problems you encounter.",
        item_label_singular: "bug report",
        status_set: status_sets.find { |s| s.name == "Bug Workflow" },
        is_admin_only: false
      },
      {
        name: "Feature Requests",
        slug: "features",
        description: "Suggest new features and enhancements. Share your ideas to make our product better!",
        item_label_singular: "feature request",
        status_set: status_sets.find { |s| s.name == "Feature Workflow" },
        is_admin_only: false
      },
      {
        name: "General Feedback",
        slug: "feedback",
        description: "Share general thoughts, suggestions, and feedback about your experience.",
        item_label_singular: "feedback",
        status_set: status_sets.find { |s| s.name == "Feature Workflow" },
        is_admin_only: false,
        single_view: "list"
      },
      {
        name: "Internal Issues",
        slug: "internal",
        description: "Internal team discussions and administrative items.",
        item_label_singular: "issue",
        status_set: status_sets.find { |s| s.name == "Bug Workflow" },
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
        b.single_view = data[:single_view] if data[:single_view].present?
      end

      # Ensure single_view is set correctly even for existing boards
      if data[:single_view].present?
        board.update!(single_view: data[:single_view])
      end

      boards << board
    end

    boards
  end

  def create_custom_fields(boards)
    fields = []

    # Bug Reports Board Custom Fields
    bugs_board = boards.find { |b| b.name == "Bug Reports" }
    if bugs_board && bugs_board.fields.empty?
      bug_fields = bugs_board.fields.create!([
        {
          label: "Severity",
          field_type: "select_field",
          field_options: [ "Low", "Medium", "High", "Critical" ],
          required: true,
          position: 0
        },
        {
          label: "Operating System",
          field_type: "select_field",
          field_options: [ "Windows 11", "Windows 10", "macOS Sonoma", "macOS Ventura", "macOS Monterey", "Ubuntu 22.04", "Ubuntu 20.04", "iOS 17", "iOS 16", "Android 14", "Android 13", "Other" ],
          required: false,
          position: 1
        },
        {
          label: "Browser",
          field_type: "select_field",
          field_options: [ "Chrome", "Firefox", "Safari", "Edge", "Opera", "Brave", "Arc", "Mobile Safari", "Chrome Mobile", "Firefox Mobile", "Samsung Internet", "Other" ],
          required: false,
          position: 2
        },
        {
          label: "Steps to Reproduce",
          field_type: "text_area",
          placeholder: "Please list the steps to reproduce this issue...",
          required: true,
          position: 3
        }
      ])
      fields.concat(bug_fields)
    end

    # Feature Requests Board Custom Fields
    features_board = boards.find { |b| b.name == "Feature Requests" }
    if features_board && features_board.fields.empty?
      feature_fields = features_board.fields.create!([
        {
          label: "Would Pay Extra for This Feature",
          field_type: "select_field",
          field_options: [ "Yes", "No" ],
          required: false,
          position: 0
        }
      ])
      fields.concat(feature_fields)
    end

    fields
  end

  def create_sample_tickets(boards, sample_users, statuses)
    tickets = []

    # Bug Reports - Create 3-4 tickets per status for better distribution
    bugs_board = boards.find { |b| b.name == "Bug Reports" }
    if bugs_board && statuses[:bug]
      bug_ticket_templates = {
        new: [
          {
            title: "Login button not working on mobile Safari",
            description: "When I try to log in using Safari on iPhone, the login button doesn't respond to taps. Works fine on Chrome and other browsers.",
            severity: "High", os: "iOS 17", browser: "Mobile Safari"
          },
          {
            title: "Page crashes when uploading videos",
            description: "The entire page becomes unresponsive when trying to upload video files larger than 50MB.",
            severity: "Critical", os: "Windows 11", browser: "Chrome"
          },
          {
            title: "Text input fields not accepting special characters",
            description: "Cannot type symbols like @, #, $ in description fields. They just don't appear.",
            severity: "Medium", os: "macOS Sonoma", browser: "Safari"
          },
          {
            title: "Profile image upload shows wrong preview",
            description: "When uploading a new profile image, the preview shows a completely different image.",
            severity: "Low", os: "Ubuntu 22.04", browser: "Firefox"
          }
        ],
        triaged: [
          {
            title: "Dashboard loading very slowly",
            description: "The main dashboard takes 15-20 seconds to load, which feels way too slow. Other pages load quickly.",
            severity: "High", os: "Windows 11", browser: "Chrome"
          },
          {
            title: "Charts not rendering on older browsers",
            description: "Dashboard charts show as blank squares in Internet Explorer 11 and older Edge versions.",
            severity: "Medium", os: "Windows 10", browser: "Edge"
          },
          {
            title: "Search auto-complete causing memory leaks",
            description: "After using search for a while, the browser becomes sluggish and eventually crashes.",
            severity: "High", os: "macOS Ventura", browser: "Chrome"
          }
        ],
        in_progress: [
          {
            title: "Email notifications not being sent",
            description: "I've enabled email notifications in my settings, but I'm not receiving any emails when there are updates.",
            severity: "High", os: "macOS Sonoma", browser: "Safari"
          },
          {
            title: "Mobile menu doesn't close after selection",
            description: "On mobile devices, the hamburger menu stays open after selecting a menu item.",
            severity: "Medium", os: "iOS 17", browser: "Mobile Safari"
          },
          {
            title: "Date picker shows wrong month",
            description: "The date picker component is off by one month - selecting January shows December.",
            severity: "Medium", os: "Android 14", browser: "Chrome Mobile"
          },
          {
            title: "Keyboard navigation broken in forms",
            description: "Tab key doesn't move focus between form fields in the expected order.",
            severity: "Medium", os: "Windows 11", browser: "Firefox"
          }
        ],
        testing: [
          {
            title: "Search results showing deleted items",
            description: "When I search for tickets, the results include items that have been deleted. Clicking shows 404.",
            severity: "Medium", os: "Ubuntu 22.04", browser: "Firefox"
          },
          {
            title: "Export function generates corrupted CSV files",
            description: "Downloaded CSV files from the export feature cannot be opened in Excel or Google Sheets.",
            severity: "High", os: "Windows 10", browser: "Edge"
          },
          {
            title: "API rate limiting too aggressive",
            description: "Mobile app gets rate-limited after just 10 requests per minute, making it unusable.",
            severity: "High", os: "iOS 16", browser: "Mobile App"
          }
        ],
        fixed: [
          {
            title: "File upload breaks with large images",
            description: "Trying to upload images larger than 2MB causes the upload to fail with a generic error message.",
            severity: "Low", os: "Windows 10", browser: "Edge"
          },
          {
            title: "Timezone display incorrect for users",
            description: "All timestamps show in UTC instead of the user's local timezone setting.",
            severity: "Medium", os: "macOS Monterey", browser: "Chrome"
          },
          {
            title: "Duplicate entries in dropdown menus",
            description: "Several dropdown menus show duplicate options, making selection confusing.",
            severity: "Low", os: "Ubuntu 20.04", browser: "Firefox"
          }
        ],
        wont_fix: [
          {
            title: "Support for Internet Explorer 6",
            description: "Please add support for Internet Explorer 6 for legacy systems in our organization.",
            severity: "Low", os: "Windows XP", browser: "Internet Explorer 6"
          },
          {
            title: "Make all text blink for attention",
            description: "It would be great if all important text could blink to grab user attention.",
            severity: "Low", os: "Windows 11", browser: "Chrome"
          }
        ]
      }

      bug_ticket_templates.each do |status_key, template_tickets|
        status = statuses[:bug][status_key]
        next unless status

        template_tickets.each do |template|
          user = sample_users.sample || nil

          field_values = {
            "severity" => template[:severity],
            "operating_system" => template[:os],
            "browser" => template[:browser],
            "steps_to_reproduce" => "#{template[:description]}\n\nSteps to reproduce:\n1. Navigate to the affected area\n2. Perform the described action\n3. Observe the issue"
          }

          ticket = Alto::Ticket.create!(
            title: template[:title],
            description: template[:description],
            board: bugs_board,
            user: user,
            status_slug: status.slug,
            field_values: field_values,
            created_at: rand(30.days).seconds.ago
          )
          tickets << ticket
        end
      end
    end

    # Feature Requests - Create 3-4 tickets per status
    features_board = boards.find { |b| b.name == "Feature Requests" }
    if features_board && statuses[:feature]
      feature_ticket_templates = {
        proposed: [
          {
            title: "Dark mode support",
            description: "It would be great to have a dark mode option in the user preferences. Many modern applications offer this.",
            would_pay: "Yes"
          },
          {
            title: "Two-factor authentication",
            description: "Add 2FA support for enhanced security. Support for TOTP apps like Google Authenticator.",
            would_pay: "Yes"
          },
          {
            title: "Keyboard shortcuts for power users",
            description: "Add keyboard shortcuts for common actions like creating tickets (Ctrl+N), searching (Ctrl+K), etc.",
            would_pay: "No"
          },
          {
            title: "Custom email templates",
            description: "Allow administrators to customize the email notification templates with company branding.",
            would_pay: "Yes"
          }
        ],
        under_review: [
          {
            title: "Bulk actions for ticket management",
            description: "As an admin, I often need to update multiple tickets at once. Bulk status changes, assignments, etc.",
            would_pay: "No"
          },
          {
            title: "Advanced user permissions",
            description: "More granular permission system with role-based access control for different board sections.",
            would_pay: "Yes"
          },
          {
            title: "API webhooks for integrations",
            description: "Webhook support so external systems can be notified when tickets are created or updated.",
            would_pay: "Yes"
          }
        ],
        approved: [
          {
            title: "Advanced search and filtering",
            description: "Enhanced search with filters by date range, user, tags, status, and saved search queries.",
            would_pay: "Yes"
          },
          {
            title: "Ticket templates for common issues",
            description: "Pre-defined templates for common types of tickets to speed up the creation process.",
            would_pay: "No"
          },
          {
            title: "Calendar view for deadlines",
            description: "A calendar interface showing tickets with due dates and milestones for better project planning.",
            would_pay: "Yes"
          },
          {
            title: "Real-time notifications",
            description: "Push notifications and real-time updates when tickets are modified or commented on.",
            would_pay: "No"
          }
        ],
        in_development: [
          {
            title: "Mobile app",
            description: "A native mobile app with push notifications, offline support, and camera integration.",
            would_pay: "Yes"
          },
          {
            title: "Rich text editor with formatting",
            description: "Replace plain text areas with a rich text editor supporting markdown, links, and inline images.",
            would_pay: "No"
          },
          {
            title: "Time tracking for tickets",
            description: "Built-in time tracking functionality to log hours spent on tickets for billing and reporting.",
            would_pay: "Yes"
          }
        ],
        released: [
          {
            title: "Integration with Slack",
            description: "Slack integration with channel notifications, ticket creation from Slack, and status commands.",
            would_pay: "No"
          },
          {
            title: "File attachments support",
            description: "Allow users to attach screenshots, documents, and other files to tickets and comments.",
            would_pay: "Yes"
          },
          {
            title: "Email-to-ticket creation",
            description: "Create tickets by sending emails to a designated address, great for customer support workflows.",
            would_pay: "Yes"
          }
        ],
        rejected: [
          {
            title: "AI-powered ticket categorization",
            description: "Using machine learning to automatically categorize tickets. Probably too ambitious for now.",
            would_pay: "No"
          },
          {
            title: "Blockchain integration for ticket history",
            description: "Use blockchain to create an immutable history of all ticket changes and comments.",
            would_pay: "No"
          }
        ]
      }

      feature_ticket_templates.each do |status_key, template_tickets|
        status = statuses[:feature][status_key]
        next unless status

        template_tickets.each do |template|
          user = sample_users.sample

          field_values = {
            "would_pay_extra_for_this_feature" => template[:would_pay]
          }

          ticket = Alto::Ticket.create!(
            title: template[:title],
            description: template[:description],
            board: features_board,
            user: user,
            status_slug: status.slug,
            field_values: field_values,
            created_at: rand(45.days).seconds.ago
          )
          tickets << ticket
        end
      end
    end

    # General Feedback - More varied feedback
    feedback_board = boards.find { |b| b.name == "General Feedback" }
    if feedback_board
      feedback_tickets = [
        {
          title: "Love the new interface design!",
          description: "Just wanted to say the recent UI update looks fantastic. Much cleaner and more intuitive than before."
        },
        {
          title: "Suggestion: keyboard shortcuts",
          description: "It would be nice to have keyboard shortcuts for common actions. Would speed up workflow for power users."
        },
        {
          title: "Documentation could be better",
          description: "The help docs are a bit sparse. More examples and screenshots would be helpful, especially for admin features."
        },
        {
          title: "Great customer support experience",
          description: "Had an issue last week and the support team was super responsive and helpful. Really appreciate it!"
        },
        {
          title: "Performance has improved significantly",
          description: "The latest updates have made everything much faster. Loading times are down and everything feels snappy."
        },
        {
          title: "Mobile experience needs work",
          description: "The mobile version is functional but could use some UX improvements. The buttons are a bit small."
        },
        {
          title: "Training materials are excellent",
          description: "The onboarding videos and tutorials really helped our team get up to speed quickly."
        },
        {
          title: "Would like more customization options",
          description: "It would be great to customize the dashboard layout and choose which widgets to display."
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
    end

    # Internal Issues - More systematic coverage
    internal_board = boards.find { |b| b.name == "Internal Issues" }
    if internal_board && statuses[:bug]
      internal_tickets = [
        {
          title: "Server migration planning",
          description: "Need to plan the migration to the new server infrastructure. Key considerations include downtime minimization and data backup strategy.",
          status_slug: statuses[:bug][:new].slug
        },
        {
          title: "Update security dependencies",
          description: "Several security vulnerabilities reported in our dependencies. Need to update Rails and other gems.",
          status_slug: statuses[:bug][:triaged].slug
        },
        {
          title: "Database performance optimization",
          description: "Query performance has degraded. Need to analyze slow queries and add proper indexing.",
          status_slug: statuses[:bug][:in_progress].slug
        },
        {
          title: "Backup system verification",
          description: "Regular verification that our backup systems are working correctly and data can be restored.",
          status_slug: statuses[:bug][:testing].slug
        },
        {
          title: "SSL certificate renewal automation",
          description: "Automate SSL certificate renewals to prevent expiration issues in production.",
          status_slug: statuses[:bug][:fixed].slug
        },
        {
          title: "Legacy API deprecation timeline",
          description: "Plan the deprecation of legacy API endpoints and communication strategy for affected clients.",
          status_slug: statuses[:bug][:new].slug
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
      when "Bug Reports"
        # Bug reports get moderate upvotes
        rand(1..8)
      when "Feature Requests"
        # Feature requests can be very popular
        case ticket.status_slug
        when "approved", "in_development", "released"
          rand(5..15)
        when "proposed", "under_review"
          rand(2..10)
        else
          rand(1..5)
        end
      when "General Feedback"
        # General feedback gets fewer upvotes
        rand(1..6)
      else
        rand(1..4)
      end

      # Create upvotes from random users
      upvote_count = [ popularity_factor, sample_users.length ].min
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

  def create_sample_tags(boards)
    tags = []

    # Bug Reports Board Tags
    bugs_board = boards.find { |b| b.name == "Bug Reports" }
    if bugs_board
      bug_tags = [
        { name: "critical", color: "#dc2626" },
        { name: "ui-bug", color: "#ea580c" },
        { name: "performance", color: "#ca8a04" },
        { name: "mobile", color: "#2563eb" },
        { name: "browser-specific", color: "#7c3aed" },
        { name: "regression", color: "#be185d" },
        { name: "security", color: "#dc2626" },
        { name: "data-loss", color: "#dc2626" }
      ]

      bug_tags.each do |tag_data|
        tag = Alto::Tag.find_or_create_by!(name: tag_data[:name], board: bugs_board) do |t|
          t.color = tag_data[:color]
        end
        tags << tag
      end
    end

    # Feature Requests Board Tags
    features_board = boards.find { |b| b.name == "Feature Requests" }
    if features_board
      feature_tags = [
        { name: "enhancement", color: "#16a34a" },
        { name: "user-experience", color: "#2563eb" },
        { name: "integration", color: "#7c3aed" },
        { name: "api", color: "#059669" },
        { name: "mobile-app", color: "#2563eb" },
        { name: "accessibility", color: "#0891b2" },
        { name: "admin-tools", color: "#be185d" },
        { name: "reporting", color: "#ca8a04" },
        { name: "automation", color: "#059669" },
        { name: "enterprise", color: "#374151" }
      ]

      feature_tags.each do |tag_data|
        tag = Alto::Tag.find_or_create_by!(name: tag_data[:name], board: features_board) do |t|
          t.color = tag_data[:color]
        end
        tags << tag
      end
    end

    # General Feedback Board Tags
    feedback_board = boards.find { |b| b.name == "General Feedback" }
    if feedback_board
      feedback_tags = [
        { name: "praise", color: "#16a34a" },
        { name: "suggestion", color: "#2563eb" },
        { name: "complaint", color: "#dc2626" },
        { name: "documentation", color: "#ca8a04" },
        { name: "training", color: "#7c3aed" },
        { name: "onboarding", color: "#059669" }
      ]

      feedback_tags.each do |tag_data|
        tag = Alto::Tag.find_or_create_by!(name: tag_data[:name], board: feedback_board) do |t|
          t.color = tag_data[:color]
        end
        tags << tag
      end
    end

    # Internal Issues Board Tags
    internal_board = boards.find { |b| b.name == "Internal Issues" }
    if internal_board
      internal_tags = [
        { name: "infrastructure", color: "#374151" },
        { name: "security", color: "#dc2626" },
        { name: "maintenance", color: "#ca8a04" },
        { name: "urgent", color: "#dc2626" },
        { name: "planning", color: "#2563eb" },
        { name: "technical-debt", color: "#ea580c" }
      ]

      internal_tags.each do |tag_data|
        tag = Alto::Tag.find_or_create_by!(name: tag_data[:name], board: internal_board) do |t|
          t.color = tag_data[:color]
        end
        tags << tag
      end
    end

    tags
  end

  def create_sample_taggings(tickets, tags)
    taggings = []

    tickets.each do |ticket|
      # Get tags for this ticket's board
      board_tags = tags.select { |tag| tag.board == ticket.board }
      next if board_tags.empty?

      # Assign 1-3 tags per ticket with realistic patterns
      tag_count = case ticket.board.name
      when "Bug Reports"
        # Bug reports often have multiple tags (severity, category, etc.)
        rand(1..3)
      when "Feature Requests"
        # Feature requests tend to have 2-3 category tags
        rand(2..3)
      when "General Feedback"
        # General feedback usually has 1-2 tags
        rand(1..2)
      when "Internal Issues"
        # Internal issues often have specific categorization
        rand(1..2)
      else
        rand(1..2)
      end

      selected_tags = board_tags.sample(tag_count)

      selected_tags.each do |tag|
        begin
          tagging = Alto::Tagging.find_or_create_by!(taggable: ticket, tag: tag)
          taggings << tagging
        rescue ActiveRecord::RecordInvalid => e
          # Skip duplicates if any
        end
      end
    end

    taggings
  end
end
