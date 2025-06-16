module Alto
  class CallbackManager
    def self.call(method_name, *args)
      new.call(method_name, *args)
    end

    def call(method_name, *args)
      if main_app_controller.respond_to?(method_name, true)
        main_app_controller.send(method_name, *args)
      end
    rescue => e
      Rails.logger.warn "Alto callback #{method_name} failed: #{e.message}"
      # Don't let callback errors break the main flow
    end

    private

    def main_app_controller
      @main_app_controller ||= ::ApplicationController.new
    end
  end
end
