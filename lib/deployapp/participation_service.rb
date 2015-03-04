require 'deployapp/namespace'

include DeployApp

class DeployApp::ParticipationService
  def initialize(args)
    @environment = args[:environment] || fail("Need :environment")
    @application = args[:application] || fail("Need :application")
    @group = args[:group] || fail("Need :group")
  end

  def participating?
    fail("Implement in subclass")
  end

  def enable_participation
    fail("Implement in subclass")
  end

  def disable_participation
    fail("Implement in subclass")
  end
end
