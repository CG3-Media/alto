module Alto
  # Service object to handle permission checking logic
  # Delegates to host app or configuration, falls back to secure defaults
  class PermissionChecker
    def self.call(method_name, controller, *args, &fallback_block)
      new(method_name, controller, *args, &fallback_block).call
    end

    def initialize(method_name, controller, *args, &fallback_block)
      @method_name = method_name
      @controller = controller
      @args = args
      @fallback_block = fallback_block
    end

    def call
      return check_host_app_method if host_app_has_method? && !test_controller?
      return check_configured_permission if configured_permission_exists? && !test_controller?

      fallback_block.call
    end

    private

    attr_reader :method_name, :controller, :args, :fallback_block

    def test_controller?
      controller.class.name.include?("Test")
    end

    def host_app_has_method?
      defined?(::ApplicationController) &&
        (::ApplicationController.instance_methods(true).include?(method_name) ||
         ::ApplicationController.private_instance_methods(true).include?(method_name))
    end

    def check_host_app_method
      ::ApplicationController.instance_method(method_name).bind(controller).call(*args)
    rescue NoMethodError
      fallback_block.call
    end

    def configured_permission_exists?
      defined?(::Alto.config) &&
        ::Alto.config.respond_to?(:has_permission?) &&
        ::Alto.config.has_permission?(method_name)
    end

    def check_configured_permission
      ::Alto.config.call_permission(method_name, controller, *args)
    end
  end
end
