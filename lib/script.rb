require 'lib/log.rb'

Config.set_logger(Logger.new(STDOUT))

class XYZ
  include Config

  def initialize()
#    @logger = Logger.new(STDOUT)
  end

  def dos()
    logger.info("hello world")
  end
end


XYZ.new().dos()
