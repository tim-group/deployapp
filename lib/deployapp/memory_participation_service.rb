require 'deployapp/namespace'

include DeployApp

class DeployApp::MemoryParticipationService
  def participating()
    return     @participating==true
  end

  def enable_participation()
    @participating=true
  end

  def disable_participation()
    @participating=false
  end
end

