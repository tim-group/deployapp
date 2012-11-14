$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'rubygems'
require 'rspec'
require 'deploy/application_communicator'
require 'deploy/service_wrapper'

describe Deploy::ApplicationCommunicator do

  before do
    @status_present = Deploy::Status.new(true)
    @status_present.add("stoppable", "safe")
    @status_present.add("version", nil)

    @status_present_not_stoppable = Deploy::Status.new(true)
    @status_present_not_stoppable.add("stoppable", "unsafe")
    @status_present_not_stoppable.add("version", nil)

    @status_not_present = Deploy::Status.new(false)
    @status_not_present.add("stoppable", nil)
    @status_not_present.add("version", nil)

  end

  it 'stops app if stoppable' do
    mock_status_retriever = double( Deploy::StatusRetriever.new)
    mock_service_wrapper = double()

    service_communicator = Deploy::ApplicationCommunicator.new({
      :config_file => "f",
      :service_name => "myservice",
      :start_timeout => 1,
      :stop_timeout => 2,
      :status_retriever => mock_status_retriever,
      :service_wrapper => mock_service_wrapper
    })

    mock_status_retriever.stub(:retrieve).with("http://localhost:").and_return(@status_present, @status_not_present, @status_not_present,@status_not_present)
    mock_service_wrapper.should_receive(:stop_service).with("myservice")
    service_communicator.stop()
  end

  it 'does not stop app if not stoppable' do
    mock_status_retriever = double( Deploy::StatusRetriever.new)
    mock_service_wrapper = double()

    service_communicator = Deploy::ApplicationCommunicator.new({
      :config_file => "f",
      :service_name => "myservice",
      :start_timeout => 1,
      :stop_timeout => 2,
      :status_retriever => mock_status_retriever,
      :service_wrapper => mock_service_wrapper
    })

    mock_status_retriever.stub(:retrieve).with("http://localhost:").and_return(@status_present_not_stoppable)
    mock_service_wrapper.should_not_receive(:stop_service).with("myservice")
    expect {  service_communicator.stop()}.should raise_error
  end

end