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

class DeployApp::ArtifactResolvers::DockerArtifactResolver
  include DeployApp::Util::Log
  def initialize(_args)
  end

  def can_resolve(_coords)
    puts 'docker can_resolve called'
    true
  end

  def resolve(coords)
    cmd "/usr/bin/docker pull repo.net.local:8080/timgroup/#{coords.name.downcase}:#{coords.version}"
    cmd "/usr/bin/docker tag repo.net.local:8080/timgroup/#{coords.name.downcase}:#{coords.version} \
          repo.net.local:8080/timgroup/#{coords.name.downcase}:current"
  end

  def clean_old_artifacts
    cmd "/usr/bin/docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v /etc:/etc \
          -e MINIMUM_IMAGES_TO_SAVE=3 repo.net.local:8080/timgroup/docker-gc"
  end

  def cmd(cmd, include_newlines = false)
    start_time = Time.now
    logger.debug("running command #{cmd}")

    output = ""
    IO.popen("#{cmd} 2>&1", "w+") do |pipe|
      # open in write mode and then close the output stream so that the subprocess doesn't capture our STDIN
      pipe.close_write
      pipe.each_line do |line|
        logger.debug("> " + line.chomp)
        output += line.chomp
        output += "\n" if include_newlines
      end
    end

    exit_status = $?
    if exit_status != 0
      logger.debug("command #{cmd} returned non-zero error code #{exit_status}, output: #{output}")
      fail "command #{cmd} returned non-zero error code #{exit_status}, output: #{output}"
    end
    elapsed_time = Time.now - start_time
    logger.debug("command #{cmd} took #{elapsed_time}s")
    output
  end
end
