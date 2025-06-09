module FeedbackBoard
  module Admin
    class DashboardController < ::FeedbackBoard::ApplicationController
      before_action :ensure_admin_access

      def index
        @total_boards = Board.count
        @total_tickets = Ticket.count
        @open_tickets = Ticket.by_status('open').count
        @recent_tickets = Ticket.includes(:upvotes, :comments, :board).recent.limit(5)
        @recent_comments = Comment.includes(:ticket, :upvotes).recent.limit(5)

        # Stats for the last 30 days
        @tickets_this_month = Ticket.where(created_at: 30.days.ago..Time.current).count
        @comments_this_month = Comment.where(created_at: 30.days.ago..Time.current).count

        # Board-specific stats
        @board_stats = Board.includes(:tickets).ordered.map do |board|
          {
            board: board,
            tickets_count: board.tickets_count,
            open_tickets_count: board.tickets.by_status('open').count,
            recent_activity: board.recent_tickets(3)
          }
        end
      end

      private

      def ensure_admin_access
        unless can_access_admin?
          redirect_to feedback_board.root_path, alert: 'You do not have permission to access the admin area'
        end
      end
    end
  end
end
