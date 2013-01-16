require 'deploy/namespace'
require 'deploy/coord'
require 'util/log'

class Deploy::ApplicationInstance
  include Util::Log

  attr_reader :application_instance_config, :application_communicator, :artifact_resolver

  def initialize(args)
    @application_instance_config = args[:application_instance_config]
    @artifact_resolver = args[:artifact_resolver]
    @application_communicator = args[:application_communicator]
    @participation_service = args[:participation_service] or raise "Please provide a participation service"
  end

  def status()
    if @application_communicator!=nil
      status = @application_communicator.get_status
    else
      status = Status::Status.new(false)
    end

    return {
      :application=>@application_instance_config.application,
      :group=>@application_instance_config.group,
      :version=>status.version,
      :present=>status.present?,
      :participating=>@participation_service.participating(),
      :health=>status.health
    }
  end

  def update_to_version(version)
    @artifact_resolver.resolve(Deploy::Coord.new(:name=>@application_instance_config.application(), :type=>"jar", :version=>version))

    if (@application_communicator.get_status.present?)
      @application_communicator.stop()
    end
    @application_communicator.start()
  end

  def enable_participation()
    logger.info("enabling participation")
    @participation_service.enable_participation()
  end

  def disable_participation()
    logger.info("disabling participation")
    @participation_service.disable_participation()
  end
end
