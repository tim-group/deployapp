require 'deployapp/namespace'
require 'deployapp/coord'
require 'deployapp/util/log'

class DeployApp::ApplicationInstance
  include DeployApp::Util::Log

  attr_reader :application_instance_config, :application_communicator, :artifact_resolver

  def initialize(args)
    @application_instance_config = args[:application_instance_config]

    if args[:artifact_resolver].nil?
      artifacts_dir = @application_instance_config.artifacts_dir
      latest_jar = @application_instance_config.latest_jar

      if (@application_instance_config.artifactresolver.eql?('docker'))
        @artifact_resolver = DeployApp::ArtifactResolvers::DockerArtifactResolver.new({})
      else
        @artifact_resolver = DeployApp::ArtifactResolvers::ProductStoreArtifactResolver.new(
          :artifacts_dir    => artifacts_dir,
          :latest_jar       => latest_jar,
          :ssh_key_location => @application_instance_config.ssh_key_location
        )
      end
    else
      @artifact_resolver = args[:artifact_resolver]
    end

    @application_communicator = args[:application_communicator]
    @participation_service = args[:participation_service] or fail "Please provide a participation service"
    @application_with_group = "#{@application_instance_config.application} #{@application_instance_config.group}"
  end

  def status
    if !@application_communicator.nil?
      status = @application_communicator.get_status
    else
      status = Status::Status.new(false)
    end

    return_status = {
      :application   => @application_instance_config.application,
      :group         => @application_instance_config.group,
      :cluster       => @application_instance_config.cluster,
      :version       => status.version,
      :present       => status.present?,
      :participating => @participation_service.participating? && status.present?,
      :health        => status.health,
      :stoppable     => status.stoppable?
    }

    logger.info("Status: #{return_status}")
    return_status
  end

  def get_artifact(version)
    coords = DeployApp::Coord.new(:name => @application_instance_config.application, :type => "jar", :version => version)
    @artifact_resolver.resolve(coords) || fail("unable to resolve #{coords.string}")
  end

  def update_to_version(version)
    get_artifact(version)
    restart
  end

  def enable_participation
    logger.info("enabling participation")
    @participation_service.enable_participation
  end

  def disable_participation
    logger.info("disabling participation")
    @participation_service.disable_participation
  end

  def kill
    if @application_communicator.get_status.present?
      logger.info('hard killing application')
      @application_communicator.kill
    else
      logger.info("not hard killing the application as it is already stopped")
    end
  end

  def stop
    if @application_communicator.get_status.present?
      logger.info('stopping application')
      @application_communicator.stop
    else
      logger.info("not stopping the application as it is already stopped")
    end
  end

  def restart
    logger.info("restarting #{@application_with_group}")
    if @application_communicator.get_status.present?
      logger.info("stopping #{@application_with_group}")
      @application_communicator.stop
    else
      logger.info("not stopping the application as it is already stopped")
    end
    logger.info("starting #{@application_with_group}")
    @application_communicator.start
  end

  def rolling_restart
    participating = @participation_service.participating?
    disable_participation if participating
    restart
    enable_participation if participating
  end
end
