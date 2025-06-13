module Alto
  class Board < ApplicationRecord
    include Sluggable

    has_many :tickets, dependent: :restrict_with_error
    has_many :fields, dependent: :destroy, class_name: "Alto::Field"
    has_many :tags, dependent: :destroy, class_name: "Alto::Tag"
    belongs_to :status_set

    # Enable nested attributes for fields - this is our Rails Way foundation!
    accepts_nested_attributes_for :fields,
                                  allow_destroy: true,
                                  reject_if: ->(attributes) {
                                    # Reject if marked for destruction
                                    return true if attributes["_destroy"] == "1" || attributes["_destroy"] == true

                                    # Reject if label is blank (required field)
                                    attributes["label"].blank?
                                  }

    # Handle custom fields data from the ReactiveRailsForm
    def fields_data=(data)
      return if data.blank?

      begin
        fields_array = data.is_a?(String) ? JSON.parse(data) : data

        # Build fields_attributes hash for Rails nested attributes
        fields_attrs = {}

        # Mark existing fields for destruction
        self.fields.each_with_index do |field, idx|
          fields_attrs[idx.to_s] = {
            id: field.id,
            _destroy: "1"
          }
        end

        # Add new/updated fields
        fields_array.each_with_index do |field_data, index|
          attr_key = (self.fields.size + index).to_s

          field_attrs = {
            label: field_data["label"],
            field_type: field_data["field_type"] || "text_field",
            required: field_data["required"] || false,
            placeholder: field_data["placeholder"],
            position: field_data["position"] || index
          }

          # Handle options for select fields
          if field_data["options"].present?
            field_attrs[:field_options] = field_data["options"].split("\n").map(&:strip).reject(&:blank?)
          end

          # Include ID if updating existing field
          if field_data["id"].present? && !field_data["id"].to_s.empty?
            field_attrs[:id] = field_data["id"]
            # Find the existing field in our destruction list and remove the _destroy flag
            existing_key = fields_attrs.keys.find { |k| fields_attrs[k][:id].to_s == field_data["id"].to_s }
            if existing_key
              fields_attrs[existing_key] = field_attrs
            else
              fields_attrs[attr_key] = field_attrs
            end
          else
            fields_attrs[attr_key] = field_attrs
          end
        end

        # Use Rails nested attributes assignment
        self.fields_attributes = fields_attrs

      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse fields_data JSON: #{e.message}"
      end
    end

    # Getter for fields_data (for form repopulation if needed)
    def fields_data
      fields.map do |field|
        {
          id: field.id,
          label: field.label,
          field_type: field.field_type,
          required: field.required,
          placeholder: field.placeholder,
          options: field.field_options&.join("\n"),
          position: field.position
        }
      end.to_json
    end

    validates :name, presence: true, length: { maximum: 100 }
    validates :slug, uniqueness: true
    validates :item_label_singular, presence: true, length: { maximum: 50 },
              format: { with: /\A[a-z ]+\z/i, message: "only letters and spaces allowed" }
    validates :status_set, presence: true

    # View enforcement enum
    enum :single_view, { card: "card", list: "list" }, suffix: true

    scope :ordered, -> { order(:name) }
    scope :public_boards, -> { where(is_admin_only: false) }
    scope :admin_only_boards, -> { where(is_admin_only: true) }

    def slug_source_attribute
      :name
    end

    def tickets_count
      tickets.count
    end

    def recent_tickets(limit = 5)
      tickets.recent.limit(limit)
    end

    def popular_tickets(limit = 5)
      tickets.popular.limit(limit)
    end

    # Search tickets within this board
    def search_tickets(query)
      tickets.search(query)
    end

    # Check if board can be safely deleted (no tickets)
    def can_be_deleted?
      tickets_count == 0 || ::Alto.configuration.allow_board_deletion_with_tickets
    end

    # Status-related methods
    def has_status_tracking?
      status_set&.has_statuses? || false
    end

    def available_statuses
      return [] unless status_set
      status_set.statuses.ordered
    end

    def available_statuses_for_user(is_admin: false)
      return [] unless status_set
      is_admin ? status_set.statuses.ordered : status_set.public_statuses.ordered
    end

    def status_options_for_select
      return [] unless status_set
      status_set.status_options_for_select
    end

    def status_options_for_select_filtered(is_admin: false)
      return [] unless status_set
      status_set.status_options_for_select_filtered(is_admin: is_admin)
    end

    def default_status_slug
      return nil unless status_set
      status_set.first_status&.slug
    end

    def default_status_slug_for_user(is_admin: false)
      return nil unless status_set

      if is_admin
        status_set.first_status&.slug
      else
        # Return the first publicly viewable status
        status_set.public_statuses.first&.slug
      end
    end

    def status_by_slug(slug)
      return nil unless status_set
      status_set.status_by_slug(slug)
    end

    # Item labeling method
    def item_name
      item_label_singular.presence || "ticket"
    end

    # Admin-only access methods
    def admin_only?
      is_admin_only?
    end

    def publicly_accessible?
      !is_admin_only?
    end

    # View enforcement methods
    def allows_view_toggle?
      single_view.blank?
    end

    def enforced_view_type
      single_view.presence
    end

    # Tagging methods
    def available_tags
      tags.ordered
    end

    def tags_for_select
      tags.ordered.pluck(:name, :id)
    end

    def find_or_create_tag(name)
      tags.find_or_create_by(name: name.to_s.strip.downcase)
    end

    def most_used_tags(limit = 10)
      tags.popular.limit(limit)
    end

    def allow_public_tagging?
      allow_public_tagging
    end

    # Scope boards based on user's admin status
    def self.accessible_to_user(user, current_user_is_admin: false)
      if current_user_is_admin
        all
      else
        public_boards
              end
      end
  end
end
