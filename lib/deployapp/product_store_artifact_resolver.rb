require 'rubygems'
require 'deployapp/namespace'
require 'deployapp/util/log'
require 'net/ssh'
require 'net/scp'

class TooManyArtifacts < Exception
end

class ArtifactNotFound < Exception
end

class DeployApp::ProductStoreArtifactResolver
  include DeployApp::Util::Log
  def initialize(args)
    @artifacts_dir = args[:artifacts_dir]
    @maxartifacts = 5
    @ssh_key_location = args[:ssh_key_location]
    @latest_jar = args[:latest_jar]
    @ssh_address = "productstore.net.local"
  end

  def resolve(coords)
    logger.info("resolving #{coords.string}")
    artifact_file="#{@artifacts_dir}/#{coords.string}"

    if File.exist?(artifact_file)
      logger.info("using artifact #{coords.string} from cache")
      FileUtils.touch(artifact_file)
    else
     logger.info("downloading artifact #{coords.string} from #{@ssh_address}")
     artifact=""
      Net::SSH.start( @ssh_address, "productstore", :keys=>[@ssh_key_location], :verbose => :debug ) do|ssh|
        cmd = "ls /opt/ProductStore/#{coords.name}/ | grep .*-#{coords.version}.*#{coords.type}"

        ssh.exec!(cmd) do |channel,stream,data|
          artifact << data.chomp if stream == :stdout
        end
      end

      raise TooManyArtifacts.new("got #{artifact}") if artifact =~ /\n/
      raise ArtifactNotFound.new("with Coords #{coords.string}") if artifact==""

      Net::SCP.start(@ssh_address, "productstore", :keys=>[@ssh_key_location]) do |scp|
        d = scp.download("/opt/ProductStore/#{coords.name}/#{artifact}", "#{@artifacts_dir}/#{coords.string}")
        d.wait
      end
    end

    self.cleanOldArtifacts
    file = File.new(artifact_file)
    FileUtils.ln_sf(file.path,  @latest_jar)

    logger.info("#{coords.string} resolved successfully")
    return file
  end

  def cleanOldArtifacts()
    files = Dir.glob("#{@artifacts_dir}/*.jar")
    sorted = files.sort_by {|filename| File.mtime("#{filename}") }
    if (sorted.size()>@maxartifacts)
      sorted[0..files.size()-@maxartifacts-1].each do |f|
        print "removing old artifact #{f}\n";
        File.delete f
      end
    end
  end
end

