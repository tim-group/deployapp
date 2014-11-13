require 'rubygems'
require 'deployapp/namespace'
require 'deployapp/util/log'

class PackageNotFound < Exception
end

class DeployApp::DebianPackageArtifactResolver
  include DeployApp::Util::Log

  def initialize(args)
    @latest_jar = args[:latest_jar]
  end

  def resolve(coords)
    logger.info("resolving #{coords.string}")

    if system("apt-get update") && system("apt-get install --dry-run #{coords.name}=#{coords.version}")
      logger.info("installing debian package #{coords.string}")
      system("apt-get install #{coords.name}=#{coords.version}")
    else
      raise PackageNotFound.new("could not find artifact with Coords #{coords.string}")
    end

    FileUtils.ln_sf("/usr/share/timgroup/#{coords.name}/latest.jar",  @latest_jar, :force=>true)
  end

end

