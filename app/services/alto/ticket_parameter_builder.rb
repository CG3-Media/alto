module Alto
  # Service object to build permitted parameters for ticket creation and updates
  class TicketParameterBuilder
    def initialize(params, user, board, permissions = {})
      @params = params
      @user = user
      @board = board
      @permissions = permissions
    end

    def build
      permitted_params = base_parameters
      permitted_params += admin_parameters if admin_access?
      permitted_params += tag_parameters if can_assign_tags?
      permitted_params += field_parameters
      permitted_params += image_parameters if image_uploads_enabled?

      @params.require(:ticket).permit(*permitted_params)
    end

    private

    attr_reader :params, :user, :board, :permissions

    def base_parameters
      [:title, :description]
    end

    def admin_parameters
      [:status_slug, :locked]
    end

    def tag_parameters
      [{ tag_ids: [] }]
    end

    def field_parameters
      [{ field_values: {} }]
    end

    def image_parameters
      [
        :images,              # Single file (multiple: false)
        { images: [] },       # Array format (if multiple: true)
        :remove_images        # Allow image removal
      ]
    end

    def admin_access?
      @permissions&.[](:can_access_admin) || false
    end

    def can_assign_tags?
      return false unless @board&.respond_to?(:tags_assignable_by?)
      @board.tags_assignable_by?(@user, can_edit_any_ticket: @permissions&.[](:can_edit_tickets) || false)
    end

    def image_uploads_enabled?
      ::Alto.configuration.image_uploads_enabled
    end
  end
end
