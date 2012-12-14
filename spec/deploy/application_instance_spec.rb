$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'test/unit'
require 'fileutils'
require 'deploy/memory_participation_service'
require 'deploy/application_instance_configuration'
require 'deploy/application_instance'
require 'deploy/stub/stub_artifact_resolver'
require 'deploy/stub/stub_application_communicator'
require 'deploy/coord'

describe Deploy::ApplicationInstance do
  require 'spec/support/matchers/include_hash'

  it 'test_generates_status_report_not_running' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:present=>false)

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>Deploy::MemoryParticipationService.new()
    )

    expected_status = {:application=>"MyArtifact",:group=>"blue",:version=>nil, :present=>false, :participating=>false}

    application_instance.status().should include_hash(expected_status)
  end

  it 'test_generates_status_report_when_running' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:present=>true, :version=>"21a")

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    expected_status = {:application=>"MyArtifact",:group=>"blue",:version=>"21a", :present=>true,:participating=>false}
    application_instance.status().should include_hash(expected_status)
 end

  it 'test_can_update_to_new_version_cold' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    application_instance.update_to_version(5)
    stub_resolver.was_last_coord?(Coord.new(:name=>"MyArtifact",:version=>5,:type=>"jar")).should eql(true)
    stub_communicator.get_status.present?.should eql(true)
  end

  it 'test_stops_application_before_launching' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:present=>true)

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()

    )

    stub_communicator.get_status.present?.should eql(true)
    application_instance.update_to_version(5)
    stub_resolver.was_last_coord?(Coord.new(:name=>"MyArtifact",:version=>5,:type=>"jar")).should eql(true)
    stub_communicator.stop_called().should eql(true)
    stub_communicator.get_status.present?.should eql(true)
  end

  it 'test_exception_raised_when_failed_to_resolve' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new(:fail_to_resolve=>true)
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new()

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    expect {
        application_instance.update_to_version(5)
    }.to raise_error Deploy::FailedToResolveArtifact

  end

  it 'test_exception_raised_when_failed_to_launch' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:fail_to_launch=>true)

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    expect {
      application_instance.update_to_version(5)
    }.to raise_error Deploy::FailedToLaunch
  end

  it 'test_exception_raised_when_failed_to_stop' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")
    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:fail_to_stop=>true,:present=>true)
    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    expect {
           application_instance.update_to_version(5)
    }.to raise_error(Deploy::FailedToStop)

  end

  it 'test_enable_participation' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:present=>true, :version=>"21a")

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()
    )

    application_instance.enable_participation()
    expected_status = {:application=>"MyArtifact",:group=>"blue",:version=>"21a", :present=>true, :participating=>true}
    application_instance.status().should include_hash(expected_status)
  end

  it 'test_disable_participation' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=Deploy::Stub::StubApplicationCommunicator.new(:present=>true, :version=>"21a")

    application_instance = Deploy::ApplicationInstance.new(
    :application_instance_config=> application_instance_config,
    :artifact_resolver=>stub_resolver,
    :application_communicator=>stub_communicator,
    :participation_service=>MemoryParticipationService.new()

    )

    application_instance.enable_participation()
    application_instance.disable_participation()

    expected_status = {:application=>"MyArtifact",:group=>"blue",:version=>"21a", :present=>true, :participating=>false}
    application_instance.status().should include_hash(expected_status)
  end

  it 'reports health' do
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new()
    application_instance_config.application("MyArtifact")
    application_instance_config.group("blue")

    stub_resolver=Deploy::Stub::StubArtifactResolver.new
    stub_communicator=double()

    status = Deploy::Status.new(true)
    status.add("health","healthy")
    stub_communicator.stub(:get_status).with().and_return(status)

    application_instance = Deploy::ApplicationInstance.new(
      :application_instance_config=> application_instance_config,
      :artifact_resolver=>stub_resolver,
      :application_communicator=>stub_communicator,
      :participation_service=>MemoryParticipationService.new()
    )

    application_instance.status().should include_hash({:health=>"healthy"})
  end

end
