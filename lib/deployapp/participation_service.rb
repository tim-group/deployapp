require 'deployapp/namespace'

include DeployApp

class DeployApp::ParticipationService
  def initialize(args)
    @environment = args[:environment] || raise("Need :environment")
    @application = args[:application] || raise("Need :application")
    @group = args[:group] || raise("Need :group")
  end

  def participating?
    raise("Implement in subclass")
  end

  def enable_participation
    raise("Implement in subclass")
  end

  def disable_participation
    raise("Implement in subclass")
  end
end
