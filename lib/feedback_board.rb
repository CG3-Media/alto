require "feedback_board/version"
require "feedback_board/engine"
require "feedback_board/configuration"

# Require dependencies
require "rails"
require "kaminari"

module FeedbackBoard
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.config
    self.configuration ||= Configuration.new
  end

  # Configuration for the FeedbackBoard engine
end
