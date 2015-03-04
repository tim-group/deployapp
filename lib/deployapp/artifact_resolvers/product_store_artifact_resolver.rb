require 'rubygems'
require 'deployapp/artifact_resolvers/namespace'
require 'deployapp/util/log'
require 'net/ssh'
require 'net/scp'
require 'time'

class TooManyArtifacts < Exception
end

class ArtifactNotFound < Exception
end

class DeployApp::ArtifactResolvers::ProductStoreArtifactResolver
  include DeployApp::Util::Log
  def initialize(args)
    @artifacts_dir = args[:artifacts_dir]
    @maxartifacts = 5
    @ssh_key_location = args[:ssh_key_location]
    @latest_jar = args[:latest_jar]
    @ssh_address = "productstore.net.local"
    @debug = false
  end

  def can_resolve(coords)
    logger.info("looking for productstore artifact #{coords.string}...")
    artifact_file = "#{@artifacts_dir}/#{coords.string}"

    if File.exist?(artifact_file)
      logger.info("...found locally")
      return true
    end

    result = fetch_artifact_names(coords).length > 0
    logger.info("...found") if result
    result
  end

  def resolve(coords)
    logger.info("resolving #{coords.string}")
    artifact_file = "#{@artifacts_dir}/#{coords.string}"

    if File.exist?(artifact_file)
      logger.info("using artifact #{coords.string} from cache")
      FileUtils.touch(artifact_file)
    else
      logger.info("downloading artifact #{coords.string} from #{@ssh_address}")
      artifact_names = fetch_artifact_names(coords)
      fail TooManyArtifacts.new("got #{artifact_names}") if artifact_names.length > 1
      fail ArtifactNotFound.new("could not find artifact with Coords #{coords.string}") if artifact_names.empty?

      start = Time.new
      Net::SCP.start(@ssh_address, "productstore", :keys => [@ssh_key_location], :config => false, :user_known_hosts_file => []) do |scp|
        d = scp.download("/opt/ProductStore/#{coords.name}/#{artifact_names[0]}", artifact_file)
        d.wait
      end
      elapsed_time = Time.new - start
      logger.info("downloaded artifact #{coords.string} #{elapsed_time} seconds")
    end

    self.clean_old_artifacts
    file = File.new(artifact_file)
    FileUtils.ln_sf(file.path,  @latest_jar)

    logger.info("#{coords.string} resolved successfully")
    file
  end

  def clean_old_artifacts
    files = Dir.glob("#{@artifacts_dir}/*.jar")
    sorted = files.sort_by { |filename| File.mtime("#{filename}") }
    if sorted.size > @maxartifacts
      sorted[0..files.size - @maxartifacts - 1].each do |f|
        print "removing old artifact #{f}\n"
        File.delete f
      end
    end
  end

  def fetch_artifact_names(coords)
    artifact = ""
    verbose = @debug ? :debug : :error
    Net::SSH.start(@ssh_address, "productstore", :keys => [@ssh_key_location], :verbose => verbose, :config => false, :user_known_hosts_file => [])  do|ssh|
      cmd = "ls /opt/ProductStore/#{coords.name}/ | grep .*-#{coords.version}.*#{coords.type}"
      ssh.exec!(cmd) do |channel, stream, data|
        artifact << data.chomp if stream == :stdout
      end
    end

    artifact.split("\n")
  end

  private :fetch_artifact_names
end
