module Alto
  class UpvotesController < ::Alto::ApplicationController
    include VotingResponses
    include VotingPermissions

    before_action :check_vote_permission
    before_action :set_board_and_upvotable
    before_action :ensure_not_archived

    def create
      @upvote = @upvotable.upvotes.build(user_id: current_user.id)

      if @upvote.save
        respond_with_vote_success(@upvotable, true)
      else
        respond_with_vote_error("Unable to upvote")
      end
    end

    def destroy
      @upvote = @upvotable.upvotes.find_by(user_id: current_user.id)

      if @upvote&.destroy
        respond_with_vote_success(@upvotable, false)
      else
        respond_with_vote_error("Unable to remove upvote")
      end
    end

    def toggle
      result = UpvoteToggler.new(@upvotable, current_user).toggle

      if result.success
        respond_with_vote_success(@upvotable, result.upvoted)
      else
        respond_with_vote_error(result.error)
      end
    end


  end
end
