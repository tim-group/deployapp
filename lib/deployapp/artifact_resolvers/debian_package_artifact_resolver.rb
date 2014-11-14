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
    logger.info("looking for debian package #{coords.name}=#{coords.version}...")
    result = system("apt-get update") && system("apt-get install --dry-run #{coords.name}=#{coords.version}")
    logger.info("...found") if result
    result
  end

  def resolve(coords)
    logger.info("installing debian package #{coords.string}")
    system("apt-get install #{coords.name}=#{coords.version}")
    FileUtils.ln_sf("/usr/share/timgroup/#{coords.name}/latest.jar",  @latest_jar, :force=>true)
  end

end

