require 'deployapp/stub/namespace'
require 'yaml'

class DeployApp::Stub::StubArtifactResolver
  def initialize(args = {})
    @fail_to_resolve = args[:fail_to_resolve] or false
  end

  def resolve(coord)
    fail DeployApp::FailedToResolveArtifact if @fail_to_resolve

    @coord = coord
  end

  def clean_old_artifacts
    @clean_old_artifacts_called = true
  end

  def was_last_coord?(coord)
    @coord.equal_to(coord)
  end

  attr_reader :clean_old_artifacts_called
end
