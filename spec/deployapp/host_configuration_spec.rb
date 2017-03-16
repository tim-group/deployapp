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

    expect(status).to eql(
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

    expect(status).to eql(
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
            application 'App1'
            group 'blue'
            additional_jvm_args '-Xms3m -Xmx5m'
            type 'none'
      }
    )
    host_configuration.add(config)

    expect(host_configuration.application_instances.size).to eql 1
    app_instance_cfg = host_configuration.application_instances.first.application_instance_config
    expect(app_instance_cfg.application).to eql 'App1'
    expect(app_instance_cfg.group).to eql 'blue'
    expect(app_instance_cfg.ssh_key_location).to eql '/root/.ssh/productstore'
    expect(app_instance_cfg.home).to eql '/opt/apps/App1-blue'
    expect(app_instance_cfg.config_filename).to eql '/opt/apps/App1-blue/config.properties'
    expect(app_instance_cfg.run_as_user).to eql 'app1'
  end

  it 'builds many app instances if loading many config files' do
    for i in 0..4
      config = %(
        application_instance {
              application "App#{i}"
              group 'blue'
              type 'none'
        })
      FileUtils.mkdir_p 'build/conf.d'
      a_file = File.new("build/conf.d/config#{i}.cfg", 'w')
      a_file.write(config)
      a_file.close
    end

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.parse('build/conf.d/')
    expect(host_configuration.application_instances.size).to eql 5
  end

  it 'retrieves status for instance' do
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
        application_instance {
            application "App#{i}"
            group 'blue'
            type 'none'
        })
      host_configuration.add(config)
    end

    status = host_configuration.status
    expect(status.size).to eql 5
    expect(status[4]).to eql(:application => 'App4', :group => 'blue', :version => nil, :present => false,
                             :participating => false, :health => nil, :cluster => 'default', :stoppable => false)

    app_status = host_configuration.status(:application => 'App4')
    expect(app_status.size).to eql 1
  end

  it 'identifies instances by key' do
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
        application_instance {
          application "App#{i}"
          group 'blue'
          type 'none'
        }
      )
      host_configuration.add(config)
    end
    instance = host_configuration.get_application_instance(:application => 'App4', :group => 'blue')
    expect(instance).to_not be_nil
  end

  it 'raises error when no instance found by key' do
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
        application_instance {
        application "App#{i}"
        group 'blue'
        type 'none'
      })
      host_configuration.add(config)
    end

    expect {
      host_configuration.get_application_instance(:application => 'BadApp', :group => 'blue')
    }.to raise_error(DeployApp::NoInstanceFound)
  end

  it 'should have wired resolver' do
    config = %(
       application_instance {
             application 'App1'
             group 'blue'
             additional_jvm_args '-Xms3m -Xmx5m'
             type 'embedded-jar'
       }
              )

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.add(config)

    application_instance = host_configuration.application_instances[0]

    expect(application_instance.artifact_resolver).to_not be_nil
    expect(application_instance.application_communicator).to_not be_nil
  end

  it 'finds services in group' do
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
        application_instance {
          application 'App#{i}'
          group 'blue'
          type 'none'
        })
      host_configuration.add(config)
    end

    status = host_configuration.status(:group => 'blue')
    expect(status.size).to eql 5

    status = host_configuration.status(:group => 'green')
    expect(status.size).to eql 0
  end

  it 'raises environment not found error when directory does not exist' do
    host_configuration = DeployApp::HostConfiguration.new(:environment => 'noexist')

    expect {
      host_configuration.parse('blah')
    }.to raise_error(DeployApp::EnvironmentNotFound)
  end
end
