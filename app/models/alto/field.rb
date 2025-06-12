module Alto
  class Field < ApplicationRecord
    self.table_name = 'alto_fields'

    belongs_to :board, class_name: 'Alto::Board'

    enum :field_type, {
      text_field: 'text_input',
      text_area: 'textarea',
      number_field: 'number',
      date_field: 'date',
      select_field: 'select',
      multiselect_field: 'multiselect'
    }

    validates :label, presence: true, length: { maximum: 100 }
    validates :field_type, presence: true
    validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

    # Serialize field options for select/multiselect fields
    serialize :field_options, coder: JSON

    # Validation for select fields to have options
    validate :select_fields_must_have_options

    scope :ordered, -> { order(:position) }
    scope :required_fields, -> { where(required: true) }

    before_create :set_position_if_needed

    def position=(value)
      @position_explicitly_set = true
      super(value)
    end

    # Get options as an array for select fields
    def options_array
      return [] unless select_field? || multiselect_field?
      field_options.is_a?(Array) ? field_options : []
    end

    # Check if field needs options configuration
    def needs_options?
      select_field? || multiselect_field?
    end

    private

    def set_position_if_needed
      # Only auto-set position if it wasn't explicitly provided
      unless @position_explicitly_set
        max_position = board&.fields&.maximum(:position) || -1
        self.position = max_position + 1
      end
    end

    def select_fields_must_have_options
      if needs_options? && options_array.empty?
        human_type = select_field? ? 'select' : 'multiselect'
        errors.add(:field_options, "must be provided for #{human_type} fields")
      end
    end
  end
end
