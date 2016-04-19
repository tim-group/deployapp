$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "../lib")
require 'test/unit'
require 'fileutils'
require 'deployapp/host_configuration'
require 'deployapp/participation_service/memory'

class HostConfigurationTest < Test::Unit::TestCase

  def test_no_instance_matches_key
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
application_instance {
application "App#{i}"
group "blue"
type "none"
})
      host_configuration.add(config)
    end

    assert_raise(DeployApp::NoInstanceFound) do
      host_configuration.get_application_instance(:application => "BadApp", :group => "blue")
    end
  end

  def test_application_instance_should_have_wired_resolver
    config = %(
       application_instance {
             application "App1"
             group "blue"
             additional_jvm_args "-Xms3m -Xmx5m"
             type "embedded-jar"
       }
              )

    host_configuration = DeployApp::HostConfiguration.new
    host_configuration.add(config)

    application_instance = host_configuration.application_instances[0]

    assert_not_nil application_instance.artifact_resolver
    assert_not_nil application_instance.application_communicator
  end

  def test_finds_services_in_group
    host_configuration = DeployApp::HostConfiguration.new
    for i in 0..4
      config = %(
application_instance {
  application "App#{i}"
  group "blue"
  type "none"
})
      host_configuration.add(config)
    end

    status = host_configuration.status(:group => "blue")
    assert_equal(5, status.size)

    status = host_configuration.status(:group => "green")
    assert_equal(0, status.size)
  end

  def test_directory_not_found
    host_configuration = DeployApp::HostConfiguration.new(:environment => "noexist")
    assert_raise(DeployApp::EnvironmentNotFound) {
      host_configuration.parse("blah")
    }
  end
end
