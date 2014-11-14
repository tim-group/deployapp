$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "../lib")
require 'test/unit'
require 'fileutils'
require 'deployapp/host_configuration'
require 'deployapp/participation_service/memory'

class HostConfigurationTest < Test::Unit::TestCase
  def test_config_definition_builds_app_instance
    config = %[
    application_instance {
          application "App1"
          group "blue"
          additional_jvm_args "-Xms3m -Xmx5m"
          type "none"
    }
    ]

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.add(config)

    assert_equal 1, host_configuration.application_instances().size()
    assert_equal "App1", host_configuration.application_instances()[0].application_instance_config.application
    assert_equal "blue", host_configuration.application_instances()[0].application_instance_config.group
    assert_equal "/root/.ssh/productstore", host_configuration.application_instances()[0].application_instance_config.ssh_key_location

    assert_equal "/opt/apps/App1-blue", host_configuration.application_instances()[0].application_instance_config.home
    assert_equal "/opt/apps/App1-blue/config.properties", host_configuration.application_instances()[0].application_instance_config.config_filename

    assert_equal "app1", host_configuration.application_instances()[0].application_instance_config.run_as_user
  end

  def test_loading_config_files_builds_many_instances
    for i in 0..4
      config = %[
application_instance {
      application "App#{i}"
      group "blue"
      type "none"
}]
      FileUtils.mkdir_p 'build/conf.d'
      aFile = File.new("build/conf.d/config#{i}.cfg", "w")
      aFile.write(config)
      aFile.close
    end

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.parse("build/conf.d/")
    assert_equal 5, host_configuration.application_instances().size()
  end

  def test_status_shown_for_instances
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %[
application_instance {
    application "App#{i}"
    group "blue"
    type "none"
}]
      host_configuration.add(config)
    end

    status = host_configuration.status()
    assert_equal(5, status.size())
    assert_equal({:application=>"App4", :group=>"blue", :version=>nil,:present=>false, :participating=>false, :health=>nil}, status[4])

    app_status = host_configuration.status(:application=>"App4")
    assert_equal(1, app_status.size())
  end

  def test_key_identifies_instance
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %[
application_instance {
  application "App#{i}"
  group "blue"
  type "none"
}]
      host_configuration.add(config)
    end
    instance = host_configuration.get_application_instance(:application=>"App4", :group=>"blue")
    assert  !instance.nil?
  end

  def test_no_instance_matches_key
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %[
application_instance {
application "App#{i}"
group "blue"
type "none"
}]
      host_configuration.add(config)
    end

    assert_raise(DeployApp::NoInstanceFound) do
      host_configuration.get_application_instance({:application=>"BadApp", :group=>"blue"})
    end
  end

  def test_application_instance_should_have_wired_resolver

    config = %[
       application_instance {
             application "App1"
             group "blue"
             additional_jvm_args "-Xms3m -Xmx5m"
             type "embedded-jar"
       }
       ]

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.add(config)

    application_instance = host_configuration.application_instances()[0]

    assert_equal(2, application_instance.artifact_resolvers.length)
    assert_not_nil application_instance.application_communicator
  end

  def test_finds_services_in_group
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %[
application_instance {
  application "App#{i}"
  group "blue"
  type "none"
}]
      host_configuration.add(config)
    end

    status = host_configuration.status({:group=>"blue"})
    assert_equal(5, status.size())

    status = host_configuration.status({:group=>"green"})
    assert_equal(0, status.size())
  end

  def test_directory_not_found
    host_configuration = DeployApp::HostConfiguration.new(:environment=>"noexist")
    assert_raise(DeployApp::EnvironmentNotFound)   {
      host_configuration.parse("blah")
    }
  end

end
