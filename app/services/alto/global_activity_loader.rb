module Alto
  # Service object to load recent activity across all boards
  class GlobalActivityLoader
    def load
      {
        recent_tickets: load_recent_tickets,
        recent_comments: load_recent_comments,
        recent_upvotes: load_recent_upvotes
      }
    end

    private

    def load_recent_tickets
      ::Alto::Ticket
        .active
        .includes(:board, :comments, :upvotes)
        .recent
        .limit(15)
    end

    def load_recent_comments
      ::Alto::Comment
        .joins(:ticket)
        .where(ticket: { archived: false })
        .includes(ticket: :board, upvotes: [])
        .recent
        .limit(15)
    end

    def load_recent_upvotes
      ::Alto::Upvote
        .joins("JOIN alto_tickets ON alto_upvotes.upvotable_type = 'Alto::Ticket' AND alto_upvotes.upvotable_id = alto_tickets.id")
        .where(alto_tickets: { archived: false })
        .includes(upvotable: :board)
        .order(created_at: :desc)
        .limit(15)
    end
  end
end
