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

  def was_last_coord?(coord)
    @coord.equal_to(coord)
  end
end
