require 'util/namespace'

class Util::CompositeLogger
  def initialize(loggers)
    @loggers = loggers
  end

  def info(msg)
    @loggers.each { |logger| logger.info(msg)}
  end

  def warn(msg)
    @loggers.each { |logger| logger.warn(msg)}
  end

  def error(msg)
    @loggers.each { |logger| logger.error(msg)}
  end
end