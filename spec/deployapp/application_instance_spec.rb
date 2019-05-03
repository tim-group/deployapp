$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'fileutils'
require 'deployapp/participation_service/memory'
require 'deployapp/application_instance_configuration'
require 'deployapp/application_instance'
require 'deployapp/stub/stub_artifact_resolver'
require 'deployapp/stub/stub_application_communicator'
require 'deployapp/coord'

describe DeployApp::ApplicationInstance do
  require 'support/matchers/include_hash'

  def memory_participation_service
    DeployApp::ParticipationService::Memory.new(
      :group => 'blue',
      :application => 'foo',
      :environment => 'qa'
    )
  end

  def default_app_instance_config
    application_instance_config = DeployApp::ApplicationInstanceConfiguration.new
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")
    application_instance_config
  end

  def artifactresolver_app_instance_config
    application_instance_config = DeployApp::ApplicationInstanceConfiguration.new
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")
    application_instance_config.artifactresolver("productstore")
    application_instance_config
  end

  def default_stub_resolver
    DeployApp::Stub::StubArtifactResolver.new
  end

  it 'is wired with the correct artifact resolver' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => false)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => artifactresolver_app_instance_config,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expected_status = {
      :application => "MyArtifact",
      :group => "blue",
      :version => nil,
      :present => false,
      :participating => false
    }

    expect(application_instance.status).to include_hash(expected_status)
    expect(application_instance.artifact_resolver.class.name).to eql("DeployApp::ArtifactResolvers::ProductStoreArtifactResolver")
  end

  it 'test_generates_status_report_not_running' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => false)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expected_status = {
      :application => "MyArtifact",
      :group => "blue",
      :version => nil,
      :present => false,
      :participating => false
    }

    expect(application_instance.status).to include_hash(expected_status)
  end

  it 'reports participation as false if the app is not running' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => false)

    memory_participation_service = double

    allow(memory_participation_service).to receive(:participating?).and_return(true)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )
    expected_status = { :present => false, :participating => false }
    expect(application_instance.status).to include_hash(expected_status)
  end

  it 'test_generates_status_report_when_running' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(
      :present => true,
      :version => "21a"
    )

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expected_status = {
      :application => "MyArtifact",
      :group => "blue",
      :version => "21a",
      :present => true,
      :participating => false
    }
    expect(application_instance.status).to include_hash(expected_status)
  end

  it 'test_can_update_to_new_version_cold' do
    stub_resolver = default_stub_resolver
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    application_instance.update_to_version(5)
    expect(stub_resolver.was_last_coord?(Coord.new(:name => "MyArtifact", :version => 5, :type => "jar"))).to eql(true)
    expect(stub_communicator.get_status.present?).to eql(true)
  end

  it 'test_stops_application_before_launching' do
    stub_resolver = default_stub_resolver
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => true)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service

    )

    expect(stub_communicator.get_status.present?).to eql(true)
    application_instance.update_to_version(5)
    expect(stub_resolver.was_last_coord?(Coord.new(:name => "MyArtifact", :version => 5, :type => "jar"))).to eql(true)
    expect(stub_communicator.stop_called).to eql(true)
    expect(stub_communicator.get_status.present?).to eql(true)
  end

  it 'test_exception_raised_when_failed_to_resolve' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => DeployApp::Stub::StubArtifactResolver.new(:fail_to_resolve => true),
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expect {
      application_instance.update_to_version(5)
    }.to raise_error DeployApp::FailedToResolveArtifact
  end

  it 'test_exception_raised_when_failed_to_launch' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:fail_to_launch => true)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expect {
      application_instance.update_to_version(5)
    }.to raise_error DeployApp::FailedToLaunch
  end

  it 'test_exception_raised_when_failed_to_stop' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:fail_to_stop => true, :present => true)
    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expect {
      application_instance.update_to_version(5)
    }.to raise_error(DeployApp::FailedToStop)
  end

  it 'test_enable_participation' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => true, :version => "21a")

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    application_instance.enable_participation
    expected_status = {
      :application => "MyArtifact",
      :group => "blue",
      :version => "21a",
      :present => true,
      :participating => true
    }
    expect(application_instance.status).to include_hash(expected_status)
  end

  it 'test_disable_participation' do
    stub_communicator = DeployApp::Stub::StubApplicationCommunicator.new(:present => true, :version => "21a")

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service

    )

    application_instance.enable_participation
    application_instance.disable_participation

    expected_status = {
      :application => "MyArtifact",
      :group => "blue",
      :version => "21a",
      :present => true,
      :participating => false
    }
    expect(application_instance.status).to include_hash(expected_status)
  end

  def app_present(present, communicator)
    allow(communicator).to receive(:get_status).and_return(Status.new(present))
  end

  it 'stops when it is running' do
    communicator = double
    app_present(true, communicator)
    expect(communicator).to receive(:stop)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => memory_participation_service
    )

    application_instance.stop
  end

  it 'does nothing when it is not running and it is asked to stop' do
    communicator = double
    app_present(false, communicator)
    expect(communicator).to_not receive(:stop)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => memory_participation_service
    )

    application_instance.stop
  end

  it 'restarts a running instance' do
    communicator = double
    app_present(true, communicator)
    expect(communicator).to receive(:stop)
    expect(communicator).to receive(:start)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => memory_participation_service
    )

    application_instance.restart
  end

  it 'rolling restarts a running instance safely' do
    communicator = double
    app_present(true, communicator)

    participation_service = double
    allow(participation_service).to receive(:participating?).and_return(true)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => participation_service
    )
    expect(application_instance).to receive(:disable_participation)
    expect(application_instance).to receive(:restart)
    expect(application_instance).to receive(:enable_participation)

    application_instance.rolling_restart
  end

  it 'rolling restarts a running instance safely respecting participating' do
    communicator = double
    app_present(true, communicator)

    non_participation_service = double
    allow(non_participation_service).to receive(:participating?).and_return(false)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => non_participation_service
    )
    expect(application_instance).not_to receive(:disable_participation)
    expect(application_instance).to receive(:restart)
    expect(application_instance).not_to receive(:enable_participation)
    application_instance.rolling_restart
  end

  it 'does not attempt to stop an already stopped instance when restarting' do
    communicator = double

    app_present(false, communicator)
    expect(communicator).to_not receive(:stop)
    expect(communicator).to receive(:start)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => communicator,
      :participation_service => memory_participation_service
    )

    application_instance.restart
  end

  it 'reports health' do
    stub_communicator = double

    status = DeployApp::Status.new(true)
    status.add("health", "healthy")
    allow(stub_communicator).to receive(:get_status).and_return(status)

    application_instance = DeployApp::ApplicationInstance.new(
      :application_instance_config => default_app_instance_config,
      :artifact_resolver => default_stub_resolver,
      :application_communicator => stub_communicator,
      :participation_service => memory_participation_service
    )

    expect(application_instance.status).to include_hash(:health => "healthy")
  end
end
