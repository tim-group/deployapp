require 'deployapp/stub/namespace'
require 'deployapp/status'

class DeployApp::Stub::StubApplicationCommunicator
  attr_accessor :running

  def initialize(args = {})
    @fail_to_launch = args[:fail_to_launch] or false
    @fail_to_stop = args[:fail_to_stop] or false
    @present = args[:present] or false
    @version = args[:version] or "undefined"
  end

  def start
    if @fail_to_launch
      fail DeployApp::FailedToLaunch
    end
    @present = true
  end

  def stop
    if @fail_to_stop
      fail DeployApp::FailedToStop
    end
    @present = false
    @stop_called = true
  end

  def get_status
    status = DeployApp::Status.new(@present)
    status.add("version", @version)
    status
  end

  attr_reader :stop_called
end
