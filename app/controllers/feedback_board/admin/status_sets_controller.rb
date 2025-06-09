module FeedbackBoard
  module Admin
    class StatusSetsController < ::FeedbackBoard::ApplicationController
      before_action :require_admin_access
      before_action :set_status_set, only: [:show, :edit, :update, :destroy]

      def index
        @status_sets = ::FeedbackBoard::StatusSet.includes(:statuses, :boards).ordered
      end

      def show
        @boards_using_status_set = @status_set.boards.ordered
      end

      def new
        @status_set = ::FeedbackBoard::StatusSet.new
        # Build initial statuses with positions
        @status_set.statuses.build(position: 0)
        @status_set.statuses.build(position: 1)
        @status_set.statuses.build(position: 2)
      end

      def create
        @status_set = ::FeedbackBoard::StatusSet.new(status_set_params)

        if @status_set.save
          redirect_to feedback_board.admin_status_set_path(@status_set),
                      notice: 'Status set was successfully created.'
        else
          # Ensure positions are set for validation errors
          @status_set.statuses.each_with_index do |status, index|
            status.position = index if status.position.blank?
          end
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @status_set.update(status_set_params)
          redirect_to feedback_board.admin_status_set_path(@status_set),
                      notice: 'Status set was successfully updated.'
        else
          # Ensure positions are set for validation errors
          @status_set.statuses.each_with_index do |status, index|
            status.position = index if status.position.blank?
          end
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @status_set.boards.any?
          redirect_to feedback_board.admin_status_sets_path,
                      alert: 'Cannot delete status set that is in use by boards.'
          return
        end

        @status_set.destroy
        redirect_to feedback_board.admin_status_sets_path,
                    notice: 'Status set was successfully deleted.'
      end

      private

      def set_status_set
        @status_set = ::FeedbackBoard::StatusSet.find(params[:id])
      end

      def status_set_params
        params.require(:status_set).permit(:name, :description, :is_default,
          statuses_attributes: [:id, :name, :color, :position, :slug, :_destroy])
      end

      def require_admin_access
        unless can_access_admin?
          redirect_to feedback_board.root_path, alert: 'Access denied.'
        end
      end
    end
  end
end
