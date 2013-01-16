require 'logger'
require 'util/namespace'

module Util::Log
  @@logger = Logger.new(STDOUT)
  def self.set_logger(logger)
    @@logger = logger
  end

  def logger
    return @@logger
  end
end

