require 'etc'
require 'deployapp/util/log'
require 'deployapp/namespace'
require 'deployapp/status'
require 'deployapp/status_retriever'
require 'deployapp/service_wrapper'
require 'deployapp/util/config_file'
require 'fileutils'
require 'facter'

include DeployApp

class DeployApp::ApplicationCommunicator
  include DeployApp::Util::Log

  def initialize(args)
    @config_file = args[:config_file] or fail DeployApp::ParameterNotPresent.new(:config_file)
    @config = DeployApp::Util::ConfigFile.new(@config_file)
    @service_name = args[:service_name] or fail DeployApp::ParameterNotPresent.new(:service_name)
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
      fail "Not stopping service #{@service_name} it is not stoppable"
    end
    wait_until_stopped
  end

  def restart
    stop
    start
  end

  def get_status
    ip = '127.0.0.1'
    prod_ip = Facter.value('ipaddress_prod')
    ip = prod_ip unless prod_ip.nil?
    status =  @status_retriever.retrieve("http://#{ip}:#{@config.port}")
    status
  end

  def wait_until_started
    @start_timeout.times do
      sleep 1
      return if get_status.present?
    end
    fail "Unable to start process in a reasonable amount of time"
  end

  def wait_until_stopped
    @stop_timeout.times do
      return if !get_status.present?
      sleep 1
    end
    fail "Gave up trying to stop instance"
  end
end
