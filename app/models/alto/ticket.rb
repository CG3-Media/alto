module Alto
  class Ticket < ApplicationRecord
    include ::Alto::Subscribable
    include ::Alto::Searchable
    include ::Alto::ImageAttachable

    belongs_to :board
    belongs_to :user, polymorphic: true
    has_many :comments, dependent: :destroy
    has_many :upvotes, as: :upvotable, dependent: :destroy
    has_many :subscriptions, class_name: "Alto::Subscription", dependent: :destroy
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings

    validates :title, presence: true, length: { maximum: 255 }
    validates :description, presence: true
    validates :user_id, presence: true
    validates :board_id, presence: true
    validate :status_slug_valid_for_board
    validate :required_custom_fields_present

    # Serialize field values as JSON
    serialize :field_values, coder: JSON

    # Host app callback hooks
    after_create :trigger_ticket_created_callback
    after_update :trigger_ticket_status_changed_callback, if: :saved_change_to_status_slug?

    # Set default status when ticket is created
    before_create :set_default_status
    # Set user_type for polymorphic association
    before_validation :set_user_type, if: -> { user_id.present? && user_type.blank? }

    scope :by_status, ->(status_slug) { where(status_slug: status_slug) }
    scope :unlocked, -> { where(locked: false) }
    scope :locked, -> { where(locked: true) }
    scope :active, -> { where(archived: false) }
    scope :archived, -> { where(archived: true) }
    scope :recent, -> { order(created_at: :desc) }
    scope :popular, -> { left_joins(:upvotes).group(:id).order("count(alto_upvotes.id) desc") }
    scope :for_board, ->(board) { where(board: board) }

    # Filter tickets by viewable statuses based on user permissions
    scope :with_viewable_statuses, ->(is_admin: false) {
      if is_admin
        all
      else
        # Only show tickets with publicly viewable statuses
        joins(board: { status_set: :statuses })
          .where("alto_tickets.status_slug = alto_statuses.slug AND alto_statuses.viewable_by_public = ?", true)
          .distinct
      end
    }





    # Tagging scopes
    scope :tagged_with, ->(tag_names) {
      tag_names = Array(tag_names)
      return all if tag_names.empty?

      # Join with taggings and tags, filter by tag names
      joins(taggings: :tag)
        .where(alto_tags: { name: tag_names })
        .group(:id)
        .having("COUNT(DISTINCT alto_tags.id) = ?", tag_names.length)
        .distinct
    }

    scope :tagged_with_any, ->(tag_names) {
      tag_names = Array(tag_names)
      return all if tag_names.empty?

      joins(taggings: :tag)
        .where(alto_tags: { name: tag_names })
        .distinct
    }

    scope :untagged, -> {
      left_joins(:taggings).where(alto_taggings: { id: nil })
    }



    def upvoted_by?(user)
      return false unless user
      upvotes.exists?(user_id: user.id)
    end

    def upvotes_count
      upvotes.count
    end

    def can_be_voted_on?
      !locked?
    end

    def can_be_commented_on?
      !locked?
    end

    def locked?
      locked || archived?
    end

    def archived?
      archived
    end

    # Status-related methods
    def status
      board.status_by_slug(status_slug)
    end

    def status_name
      status&.name || status_slug&.humanize || "Unknown"
    end

    def status_color_classes
      status&.color_classes || "bg-gray-100 text-gray-800"
    end

    def available_statuses
      board.available_statuses
    end

    def can_change_status?
      board.has_status_tracking?
    end

    # Custom field methods
    def field_value(field)
      return nil unless field_values.is_a?(Hash)
      key = field.label.parameterize.underscore
      field_values[key]
    end

    def set_field_value(field, value)
      self.field_values = {} unless field_values.is_a?(Hash)
      key = field.label.parameterize.underscore
      self.field_values[key] = value
    end

    def custom_fields
      board.fields.ordered
    end

    # Subscribable concern implementation
    def subscribable_ticket
      self
    end

    def user_email
      ::Alto.configuration.user_email.call(user_id)
    end

    def user_subscribed?(user)
      return false unless user

      begin
        user_email = ::Alto.configuration.user_email.call(user.id)
        return false unless user_email.present?

        subscriptions.exists?(email: user_email)
      rescue => e
        Rails.logger.warn "[Alto] Failed to check subscription status: #{e.message}"
        false
      end
    end

    def editable_by?(user, can_edit_any_ticket: false)
      return false unless user
      # Users can edit their own tickets, or if they have permission to edit any ticket
      user_id == user.id || can_edit_any_ticket
    end

    # Tagging methods
    def tag_with(tag_objects_or_names)
      tag_objects_or_names = Array(tag_objects_or_names)

      # Convert names to tag objects if needed
      tag_objects = tag_objects_or_names.map do |item|
        if item.is_a?(String)
          board.tags.find_by(name: item)
        else
          item
        end
      end.compact

      # Replace all current tags with new ones
      self.tags = tag_objects
    end

    def tag_list
      tags.order(:name).pluck(:name)
    end

    def tag_list=(tag_names)
      tag_names = Array(tag_names).map(&:to_s).reject(&:blank?)

      # Find existing tags for this board
      existing_tags = board.tags.where(name: tag_names)

      # Only assign existing tags (don't create new ones)
      self.tags = existing_tags
    end

    def tagged_with?(tag_name)
      tags.exists?(name: tag_name)
    end

    def add_tag(tag_or_name)
      tag = if tag_or_name.is_a?(String)
        board.tags.find_by(name: tag_or_name)
      else
        tag_or_name
      end

      if tag && !tags.include?(tag)
        tags << tag
      end
    end

    def remove_tag(tag_or_name)
      tag = if tag_or_name.is_a?(String)
        tags.find_by(name: tag_or_name)
      else
        tag_or_name
      end

      if tag
        tags.delete(tag)
      end
    end

    private

    def trigger_ticket_created_callback
      ::Alto::CallbackManager.call(:ticket_created, self, board, get_user_object(user_id))
    end

    def trigger_ticket_status_changed_callback
      old_status_slug = saved_changes["status_slug"][0]
      new_status_slug = saved_changes["status_slug"][1]
      ::Alto::CallbackManager.call(:ticket_status_changed, self, old_status_slug, new_status_slug, board, get_user_object(user_id))
    end

    def get_user_object(user_id)
      return nil unless user_id

      begin
        user_class = ::Alto.configuration.user_model.constantize
        user_class.find_by(id: user_id)
      rescue NameError
        nil
      end
    end

    def status_slug_valid_for_board
      return unless status_slug.present? && board.present?

      valid_slugs = board.status_set.status_slugs
      unless valid_slugs.include?(status_slug)
        errors.add(:status_slug, "is not valid for this board")
      end
    end

    def set_default_status
      return unless board.present?

      if status_slug.blank?
        # For regular users, ensure the default status is publicly viewable
        user_object = get_user_object(user_id)
        is_admin = user_object && user_object.respond_to?(:can?) && user_object.can?(:access_admin)
        self.status_slug = board.default_status_slug_for_user(is_admin: is_admin)
      end
    end

    def set_user_type
      self.user_type = ::Alto.configuration.user_model if user_id.present?
    end

    def required_custom_fields_present
      return unless board.present?

      board.fields.required_fields.each do |field|
        field_key = field.label.parameterize.underscore

        # During validation, check the submitted field_values directly
        # rather than using field_value(field) which might read from database
        submitted_value = if field_values.is_a?(Hash)
          field_values[field_key]
        else
          nil
        end

        if submitted_value.blank?
          errors.add("field_values_#{field_key}".to_sym, "#{field.label} is required")
        end
      end
    end
  end
end
