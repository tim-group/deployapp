require 'util/namespace'

class Util::InMemoryLogger
  def initialize()
    @infos = []
    @warns = []
    @errors = []
  end

  def info(msg)
    @infos << msg
  end

  def warn(msg)
    @warns << msg
  end

  def error(msg)
    @errors << msg
  end

  def logs
    return {
      :infos=>@infos,
      :warns=>@warns,
      :errors=>@errors
    }
  end

end