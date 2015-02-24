require 'etc'
require 'deployapp/util/log'
require 'deployapp/namespace'
require 'deployapp/status'
require 'deployapp/status_retriever'
require 'deployapp/service_wrapper'
require 'deployapp/util/config_file'
require 'fileutils'

include DeployApp

class DeployApp::ApplicationCommunicator
  include DeployApp::Util::Log

  def initialize(args)
    @config_file = args[:config_file] or raise DeployApp::ParameterNotPresent.new(:config_file)
    @config = DeployApp::Util::ConfigFile.new(@config_file)
    @service_name = args[:service_name] or raise DeployApp::ParameterNotPresent.new(:service_name)
    @start_timeout = args[:start_timeout] || 120
    @stop_timeout = args[:stop_timeout] || 60
    @status_retriever =  args[:status_retriever] || DeployApp::StatusRetriever.new
    @service_wrapper = args[:service_wrapper] || DeployApp::ServiceWrapper.new
  end

  def start
    @service_wrapper.start_service(@service_name)
    wait_until_started
  end

  def kill
    @service_wrapper.stop_service(@service_name)
    wait_until_stopped
  end

  def stop
    if get_status.stoppable?
      @service_wrapper.stop_service(@service_name)
    else
      raise "Not stopping service #{@service_name} it is not stoppable"
    end
    wait_until_stopped
  end

  def get_status
    status =  @status_retriever.retrieve("http://127.0.0.1:#{@config.port}")
    return status
  end

  def wait_until_started
    for i in (1..@start_timeout)
      sleep 1
      if get_status.present?
        return
      end
    end
    raise "Unable to start process in a reasonable amount of time"
  end

  def wait_until_stopped
    for i in (1..@stop_timeout)
      if !get_status.present?
        return
      end
      sleep 1
    end
    raise "Gave up trying to stop instance"
  end
end
