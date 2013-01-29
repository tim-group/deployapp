require 'deployapp/namespace'
include DeployApp

class DeployApp::Status
  def initialize(present)
    @components = {}
    @present = present
  end

  def add(key, value)
    @components[key] = value
  end

  def present?
    return @present
  end

  def stoppable?
    return @components["stoppable"] == "safe"
  end

  def version
    return @components["version"]
  end

  def available?
    return @components["available"] == "true"
  end

  def health
    return @components["health"]
  end
end

