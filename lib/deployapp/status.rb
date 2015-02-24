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
    @present
  end

  def stoppable?
    @components["stoppable"] == "safe"
  end

  def version
    @components["version"]
  end

  def available?
    @components["available"] == "true"
  end

  def health
    @components["health"]
  end
end
