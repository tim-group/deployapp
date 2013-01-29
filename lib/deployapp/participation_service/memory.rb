require 'deployapp/participation_service'

include DeployApp

class DeployApp::ParticipationService::Memory < DeployApp::ParticipationService
  def participating?
    return @participating==true
  end

  def enable_participation
    @participating=true
  end

  def disable_participation
    @participating=false
  end
end

