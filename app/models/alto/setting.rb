module Alto
  class Setting < ApplicationRecord
    validates :key, presence: true, uniqueness: true
    validates :value_type, inclusion: { in: %w[string boolean array] }

    # Get a setting value with proper type casting
    def self.get(key, default = nil)
      setting = find_by(key: key)
      return default unless setting

      case setting.value_type
      when "boolean"
        setting.value == "true"
      when "array"
        setting.value.present? ? JSON.parse(setting.value) : []
      else
        setting.value
      end
    end

    # Set a setting value with automatic type detection
    def self.set(key, value)
      setting = find_or_initialize_by(key: key)

      case value
      when true, false
        setting.value = value.to_s
        setting.value_type = "boolean"
      when Array
        setting.value = value.to_json
        setting.value_type = "array"
      else
        setting.value = value.to_s
        setting.value_type = "string"
      end

      setting.save!
      value
    end

    # Bulk update settings
    def self.update_settings(settings_hash)
      settings_hash.each do |key, value|
        set(key, value)
      end
    end

    # Load all settings into the configuration
    def self.load_into_configuration!
      config = ::Alto.configuration

      # Currently no database settings to load
      # App name is handled through the configuration object directly
    end
  end
end
