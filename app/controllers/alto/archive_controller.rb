module Alto
  class ArchiveController < ::Alto::ApplicationController
    before_action :set_board
    before_action :set_ticket, only: [ :archive, :unarchive ]

    def show
      @tickets = @board.tickets.archived
                      .includes(:upvotes)
                      .recent
                      .page(params[:page])
    end

    def archive
      ensure_admin_access

      @ticket.update!(archived: true)
      flash[:notice] = "Ticket has been archived."
      redirect_to board_ticket_path(@board, @ticket)
    end

    def unarchive
      ensure_admin_access

      @ticket.update!(archived: false)
      flash[:notice] = "Ticket has been unarchived."
      redirect_to board_ticket_path(@board, @ticket)
    end

    private

    def set_board
      @board = ::Alto::Board.find(params[:board_slug])
    end

    def set_ticket
      @ticket = @board.tickets.find(params[:id])
    end
  end
end
