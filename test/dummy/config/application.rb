require_relative "boot"

require "logger"
require "rails/all"

Bundler.require(*Rails.groups)
require "alto"

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.0

    # For compatibility with applications that use this config
    config.action_controller.include_all_helpers = false

    # Configuration for the application, engines, and railties goes here.
    config.filter_parameters += [
      :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
    ]
  end
end
