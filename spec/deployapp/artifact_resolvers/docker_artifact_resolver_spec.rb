$: << File.join(File.dirname(__FILE__), "..", "../lib")

require 'deployapp/artifact_resolvers/docker_artifact_resolver'
require 'deployapp/coord'

describe DeployApp::ArtifactResolvers::DockerArtifactResolver do

  before do
    @docker_artifact_resolver = DeployApp::ArtifactResolvers::DockerArtifactResolver.new({})
  end

  it 'cleans up docker resources after resolving' do
    @docker_artifact_resolver.stub(:cmd) do |_arg|
      true
    end

    coords = DeployApp::Coord.new(:name => "MyArtifact", :type => "jar", :version => nil)

    @docker_artifact_resolver.should_receive(:cmd).with('/usr/bin/docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc -e MINIMUM_IMAGES_TO_SAVE=3 repo.net.local:8080/docker-gc')

    @docker_artifact_resolver.resolve(coords)
  end
end
