require 'rubygems'
require 'deployapp/artifact_resolvers/namespace'
require 'deployapp/util/log'

class PackageNotFound < Exception
end

class DeployApp::ArtifactResolvers::CompositeArtifactResolver
  include DeployApp::Util::Log

  def initialize(args)
    @artifact_resolvers = [
      DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(
        :artifacts_dir    => args[:artifacts_dir],
        :latest_jar       => args[:latest_jar],
        :ssh_key_location => args[:ssh_key_location]
      ),
      DeployApp::ArtifactResolvers::DebianPackageArtifactResolver.new(
        :latest_jar       => args[:latest_jar]
      )]
  end

  def resolve(coords)
    @artifact_resolvers.each do |resolver|
      if (resolver.can_resolve(coords))
        resolver.resolve(coords)
        return true
      end
    end
    return false
  end

end

