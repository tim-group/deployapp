$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'deploy/EmbeddedJavaCommunicator'
require 'Coord'
require 'test/unit'
require 'net/http'
require 'socket'
require 'compatibility/namespace'

class Compatibility::StartupShutdownTest < Test::Unit::TestCase
  def setup
    File.open("build/javahttp.config.properties", "w") do |f|
      f.write("port=2003\n")
    end
  end

  def teardown
    ensure_application_is_stopped
  end

  def kill(pid)
    system("kill #{pid} > /dev/null 2>&1")
  end

  def ensure_application_is_stopped
    return if @pid.nil?
    kill(@pid)

    i = 0
    while @communicator.get_status.present?
      sleep(1)
      i += 1
      throw "Unable to kill application under test" if i > 5
    end
  end

  def test_cannot_start_on_port_already_in_use
  end

  def test_two_starts_dont_overwrite_pid_file
    @communicator = Deploy::EmbeddedJavaCommunicator.new(
      :runnable_jar => "build/javahttp.jar",
      :config_file => "build/javahttp.config.properties",
      :pid_file => "build/tmp.pid",
      :log_file => "build/console.log",
      :start_timeout => 5,
      :run_as_user => Etc.getlogin
    )
    @pid = @communicator.start

    begin
      second_pid = @communicator.start
    ensure
      kill(second_pid)
    end
    pid_file = IO.read("build/tmp.pid").chomp.to_i
    assert_equal(@pid, pid_file)
  end

  def test_status_is_not_present_when_application_not_running
    @communicator = Deploy::EmbeddedJavaCommunicator.new(
      :runnable_jar => "nonexistant.jar",
      :config_file => "build/javahttp.config.properties",
      :pid_file => "build/tmp.pid",
      :log_file => "build/console.log",
      :start_timeout => 5,
      :run_as_user => Etc.getlogin
    )

    assert ! @communicator.get_status.present?
  end

  def test_status_is_present_when_application_is_running
    @communicator = Deploy::EmbeddedJavaCommunicator.new(
      :runnable_jar => "build/javahttp.jar",
      :config_file => "build/javahttp.config.properties",
      :pid_file => "build/tmp.pid",
      :log_file => "build/console.log",
      :start_timeout => 5,
      :run_as_user => Etc.getlogin
    )
    @pid = @communicator.start

    assert @communicator.get_status.present?
  end

  def test_stopping_application_makes_it_not_present
    @communicator = Deploy::EmbeddedJavaCommunicator.new(
      :runnable_jar => "build/javahttp.jar",
      :config_file => "build/javahttp.config.properties",
      :pid_file => "build/tmp.pid",
      :log_file => "build/console.log",
      :start_timeout => 5,
      :run_as_user => Etc.getlogin
    )
    @pid = @communicator.start

    @communicator.stop

    assert ! @communicator.get_status.present?
  end
end
