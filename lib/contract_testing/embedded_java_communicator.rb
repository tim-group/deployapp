require 'etc'
require 'deployapp/util/log'
require 'deployapp/util/config_file'
require 'deployapp/namespace'
require 'deployapp/status_retriever'
require 'fileutils'

include DeployApp

class DeployApp::EmbeddedJavaCommunicator
  include DeployApp::Util::Log
  def initialize(args)
    @runnable_jar = args[:runnable_jar] or fail DeployApp::ParameterNotPresent.new(:runnable_jar)
    @config_file = args[:config_file] or fail DeployApp::ParameterNotPresent.new(:config_file)
    @config = DeployApp::Util::ConfigFile.new(@config_file)
    @pid_file = args[:pid_file] or fail DeployApp::ParameterNotPresent.new(:pid_file)
    @log_file = args[:log_file] or fail DeployApp::ParameterNotPresent.new(:log_file)
    @start_timeout = args[:start_timeout] || 60
    @stop_timeout = args[:stop_timeout] || 60
    @jvm_args = args[:jvm_args] or ""
    @status_retriever = DeployApp::StatusRetriever.new
    @run_as_user =  args[:run_as_user] or fail DeployApp::ParameterNotPresent.new(:run_as_user)
  end

  def start
    ensure_stopped

    logger.debug("launching application as #{@run_as_user}")

    as_user(@run_as_user) do
      system("deployapp/launch \"#{@jvm_args}\" \"#{@runnable_jar}\" \"#{@config_file}\" \"#{@log_file}\" \"#{@pid_file}\"")
    end

    @start_timeout.times do
      sleep 1
      return IO.read(@pid_file).to_i if get_status.present?
    end
    logcontents = IO.read(@log_file)
    fail "Unable to start process in a reasonable amount of time.\nConsole log:\n#{logcontents}"
  end

  def stop
    @stop_timeout.times do
      return if !get_status.present?
      clean_up if get_status.present? && get_status.stoppable?
      sleep 1
    end
    fail "Gave up trying to stop instance"
  end

  def ensure_stopped
    return true if @pid_file.nil?

    if File.exists?(@pid_file)
      pid = IO.read(@pid_file).to_i
      File.delete(@pid_file)
      if File.exists?("/proc/#{pid}")
        if !system("kill -9 #{pid} 2>/dev/null")
          logger.info("Failed to kill process #{pid}\n")
          return
        end
        @stop_timeout.times do
          sleep 1
          if !get_status.present?
            logger.debug("Killed process #{pid}\n")
            return
          end
        end
      end
    end
  end

  def get_status
    @status_retriever.retrieve("http://localhost:#{@config.port}")
  end

  def as_user(user, &block)
    u = (user.is_a? Integer) ? Etc.getpwuid(user) : Etc.getpwnam(user)
    Process.fork do
      Process::UID.change_privilege(u.uid)
      block.call(user)
    end
  end

  def self.to_app_described_by(properties_file)
    properties = Util::ConfigFile.new(properties_file)
    application_name = properties.get("application")
    version = properties.get("version")
    type = properties.get("type")
    start_timeout = properties.get("start_timeout") || 60

    new(
      :runnable_jar => "build/latest.jar",
      :config_file => "config/#{application_name}/config.properties",
      :log_file => "build/console.log",
      :pid_file => "build/tmp.pid",
      :start_timeout => start_timeout.to_i,
      :run_as_user => Etc.getlogin,
      :jvm_args => properties.get("jvm_args")
    )
  end
end
