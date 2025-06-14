require 'ostruct'

module Alto
  # Service object to handle upvote toggling logic
  class UpvoteToggler
    def initialize(upvotable, user)
      @upvotable = upvotable
      @user = user
    end

    def toggle
      existing_upvote = find_existing_upvote

      if existing_upvote
        remove_upvote(existing_upvote)
      else
        add_upvote
      end
    end

    private

    attr_reader :upvotable, :user

    def find_existing_upvote
      upvotable.upvotes.find_by(user_id: user.id)
    end

    def remove_upvote(upvote)
      upvote.destroy
      OpenStruct.new(success: true, upvoted: false)
    end

    def add_upvote
      upvote = upvotable.upvotes.create!(user_id: user.id)
      OpenStruct.new(success: true, upvoted: true)
    rescue ActiveRecord::RecordInvalid => e
      OpenStruct.new(success: false, error: e.message)
    end
  end
end
