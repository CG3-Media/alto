require "feedback_board/version"
require "feedback_board/engine"
require "feedback_board/database_setup"
require "feedback_board/configuration"

# Require dependencies
require "rails"
require "kaminari"

module FeedbackBoard
  def self.configure
    @configuration ||= Configuration.new
    yield(@configuration) if block_given?
    @configuration
  end

  def self.config
    @configuration ||= Configuration.new
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Ensure configuration is available immediately
  configure {}
end
