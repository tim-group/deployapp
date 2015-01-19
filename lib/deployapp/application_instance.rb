require 'deployapp/namespace'
require 'deployapp/coord'
require 'deployapp/util/log'

class DeployApp::ApplicationInstance
  include DeployApp::Util::Log

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

    return_status = {
      :application   => @application_instance_config.application,
      :group         => @application_instance_config.group,
      :version       => status.version,
      :present       => status.present?,
      :participating => @participation_service.participating? && status.present?,
      :health        => status.health
    }

    logger.info(return_status)
    return_status
  end

  def get_artifact(version)
    coords = DeployApp::Coord.new(:name=>@application_instance_config.application(), :type=>"jar", :version=>version)
    @artifact_resolver.resolve(coords) or raise "unable to resolve #{coords.string}"
  end

  def update_to_version(version)
    get_artifact(version)

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

  def kill()
    if @application_communicator.get_status().present?
      logger.info('hard killing application')
      @application_communicator.kill()
    else
      logger.info("not hard killing the application as it is already stopped")
    end
  end

  def stop()
    if @application_communicator.get_status().present?
      logger.info('stopping application')
      @application_communicator.stop()
    else
      logger.info("not stopping the application as it is already stopped")
    end
  end

end
