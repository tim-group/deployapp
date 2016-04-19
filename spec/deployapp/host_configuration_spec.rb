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
end
