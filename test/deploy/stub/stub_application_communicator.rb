require 'deploy/stub/namespace'
require 'deploy/status'

class Deploy::Stub::StubApplicationCommunicator
  attr_accessor :running

  def initialize(args={})
    @fail_to_launch = args[:fail_to_launch] or false
    @fail_to_stop = args[:fail_to_stop] or false
    @present = args[:present] or false
    @version = args[:version] or "undefined"
  end

  def start()
    if (@fail_to_launch)
      raise Deploy::FailedToLaunch
    end
    @present = true
  end

  def stop()
    if (@fail_to_stop)
      raise Deploy::FailedToStop
    end
    @present = false
    @stop_called=true
  end

  def get_status()
    status = Deploy::Status.new(@present)
    status.add("version",@version)
    return status
  end

  def stop_called
    return @stop_called
  end

end