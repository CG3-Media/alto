require "alto/version"
require "alto/engine"
require "alto/database_setup"
require "alto/configuration"

# Require dependencies
require "rails"
require "kaminari"

module Alto
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
  configure { }
end
