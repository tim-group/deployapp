$: << File.join(File.dirname(__FILE__), "..", "../lib","../test")
require 'test/unit'
require 'deployapp/embedded_java_communicator'
require 'deployapp/application_instance'

class DeployApp::EmbeddedJavaAppCommunicatorTest < Test::Unit::TestCase
  def test_reports_failure_to_launch_app
    file = File.new("build/rubbish.config","w")
    file.write("port=1111")
    file.close()

    @communicator =  EmbeddedJavaCommunicator.new(
    :log_file => "build/failed_launch.log",
    :runnable_jar => "some/bad/thing.jar",
    :pid_file => "build/failed_launch.pid",
    :config_file => "build/rubbish.config",
    :start_timeout => 1,
    :run_as_user => Etc.getlogin()
    )

    begin
      @communicator.start
      raise "expected unable-to-launch exception"
    rescue Exception => e
      assert_block do
          e.message =~ /Unable to start process in a reasonable amount of time/
      end
    end
  end
end
