require 'util/namespace'

class Util::InMemoryLogger
  def initialize()
    @debugs = []
    @infos = []
    @warns = []
    @errors = []
  end

  def debug(msg)
    @debugs << msg
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
      :debugs=>@debugs,
      :infos=>@infos,
      :warns=>@warns,
      :errors=>@errors
    }
  end

end
