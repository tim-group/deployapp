$LOAD_PATH << File.join(File.dirname(__FILE__), '..', '../lib')
require 'fileutils'
require 'deployapp/host_configuration'
require 'deployapp/participation_service/memory'

describe DeployApp::HostConfiguration do
  it 'provides the default clustername per instance when none is specified' do
    host_configuration = DeployApp::HostConfiguration.new
    config = %(
application_instance {
    application 'App'
    group 'blue'
    type 'none'
})
    host_configuration.add(config)

    status = host_configuration.status

    status.should eq(
      [{ :present => false,
         :group => 'blue',
         :stoppable => false,
         :cluster => 'default',
         :participating => false,
         :application => 'App',
         :version => nil,
         :health => nil }])
  end

  it 'allows us to configure clustername per instance' do
    host_configuration = DeployApp::HostConfiguration.new
    config = %(
application_instance {
    application 'App'
    group 'blue'
    cluster 'A'
    type 'none'
})
    host_configuration.add(config)

    status = host_configuration.status

    status.should eq(
      [{ :present => false,
         :group => 'blue',
         :stoppable => false,
         :cluster => 'A',
         :participating => false,
         :application => 'App',
         :version => nil,
         :health => nil }])
  end

  it 'builds an app instance' do
    host_configuration = DeployApp::HostConfiguration.new
    config = %(
    application_instance {
          application "App1"
          group "blue"
          additional_jvm_args "-Xms3m -Xmx5m"
          type "none"
    }
    )
    host_configuration.add(config)

    host_configuration.application_instances.size.should be(1)
    host_configuration.application_instances[0].application_instance_config.application.should eq('App1')
    host_configuration.application_instances[0].application_instance_config.group.should eq('blue')
    host_configuration.application_instances[0].application_instance_config.ssh_key_location.should eq('/root/.ssh/productstore')
    host_configuration.application_instances[0].application_instance_config.home.should eq('/opt/apps/App1-blue')
    host_configuration.application_instances[0].application_instance_config.config_filename.should eq('/opt/apps/App1-blue/config.properties')
    host_configuration.application_instances[0].application_instance_config.run_as_user.should eq('app1')
  end
end
