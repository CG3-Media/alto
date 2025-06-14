module Alto
  module Admin
    class StatusSetsController < ::Alto::ApplicationController
      before_action :require_admin_access
      before_action :set_status_set, only: [ :show, :edit, :update, :destroy ]

      def index
        @status_sets = ::Alto::StatusSet.includes(:statuses, :boards).ordered
      end

      def show
        @boards_using_status_set = @status_set.boards.ordered
      end

      def new
        @status_set = ::Alto::StatusSet.new
        # Build one initial status with default values
        @status_set.statuses.build(position: 0, viewable_by_public: true)
      end

      def create
        @status_set = ::Alto::StatusSet.new(status_set_params)

        if @status_set.save
          redirect_to alto.admin_status_set_path(@status_set),
                      notice: "Status set was successfully created."
        else
          @status_set.ensure_status_positions!
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @status_set.update(status_set_params)
          redirect_to alto.admin_status_set_path(@status_set),
                      notice: "Status set was successfully updated."
        else
          @status_set.ensure_status_positions!
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @status_set.boards.any?
          redirect_to alto.admin_status_sets_path,
                      alert: "Cannot delete status set that is in use by boards."
          return
        end

        @status_set.destroy
        redirect_to alto.admin_status_sets_path,
                    notice: "Status set was successfully deleted."
      end

      private

      def set_status_set
        @status_set = ::Alto::StatusSet.find(params[:id])
      end

      def status_set_params
        params.require(:status_set).permit(:name, :description, :is_default,
          statuses_attributes: [ :id, :name, :color, :position, :slug, :viewable_by_public, :_destroy ])
      end

      def require_admin_access
        unless can_access_admin?
          redirect_to alto.alto_home_path, alert: "Access denied."
        end
      end
    end
  end
end
