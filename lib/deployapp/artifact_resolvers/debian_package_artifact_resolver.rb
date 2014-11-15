require 'rubygems'
require 'deployapp/artifact_resolvers/namespace'
require 'deployapp/util/log'

class PackageNotFound < Exception
end

class DeployApp::ArtifactResolvers::DebianPackageArtifactResolver
  include DeployApp::Util::Log

  def initialize(args)
    @latest_jar = args[:latest_jar]
  end

  def can_resolve(coords)
    logger.info("looking for debian package #{coords.name.downcase}=#{coords.version}...")
    result = system("sudo apt-get update -qq") && system("sudo apt-get install --dry-run #{coords.name.downcase}=#{coords.version}")
    logger.info("...found") if result
    result
  end

  def resolve(coords)
    logger.info("installing debian package #{coords.string}")
    system("sudo apt-get -y install #{coords.name.downcase}=#{coords.version}")
    FileUtils.ln_sf("/usr/share/timgroup/#{coords.name.downcase}/latest.jar",  @latest_jar)
  end

end

