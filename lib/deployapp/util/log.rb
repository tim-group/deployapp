require 'logger'
require 'deployapp/util/namespace'

module DeployApp::Util::Log
  @@logger = Logger.new(STDOUT)
  def self.set_logger(logger)
    @@logger = logger
  end

  def logger
    @@logger
  end
end
