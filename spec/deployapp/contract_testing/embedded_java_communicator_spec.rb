$: << File.join(File.dirname(__FILE__), '..', '../lib')
require 'deployapp/application_instance'
require 'contract_testing/embedded_java_communicator'

describe DeployApp::EmbeddedJavaCommunicator do
  it 'reports failure to launch app' do
    file = File.new('build/rubbish.config', 'w')
    file.write('port=1111')
    file.close

    @communicator =  EmbeddedJavaCommunicator.new(
      :log_file => 'build/failed_launch.log',
      :runnable_jar => 'some/bad/thing.jar',
      :pid_file => 'build/failed_launch.pid',
      :config_file => 'build/rubbish.config',
      :start_timeout => 1,
      :run_as_user => Etc.getlogin
    )

    begin
      @communicator.start
      fail 'expected unable-to-launch exception'
    rescue Exception => e
      expect(e.message).to match(/Unable to start process in a reasonable amount of time/)
    end
  end
end
