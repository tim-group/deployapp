require 'deployapp/namespace'
require 'deployapp/application_instance_configuration'
require 'deployapp/application_instance'
require 'deployapp/artifact_resolvers/composite_artifact_resolver'
require 'deployapp/application_communicator'
require 'deployapp/participation_service/tatin'

class DeployApp::HostConfiguration
  attr_reader :app_base_dir, :run_base_dir, :log_base_dir

  def initialize(args = { :environment => "" })
    @environment  = args[:environment]
    @app_base_dir = args[:app_base_dir]
    @run_base_dir = args[:run_base_dir]
    @log_base_dir = args[:log_base_dir]

    if (@app_base_dir == nil)
      if (@environment == "")
        @app_base_dir = "/opt/apps"
      else
        @app_base_dir = "/opt/apps-#{@environment}"
      end
    end
    if (@run_base_dir == nil)
      if (@environment == "")
        @run_base_dir = "/var/run"
      else
        @run_base_dir = "/var/run/#{@environment}"
      end
    end

    if (@log_base_dir == nil)
      if (@environment == "")
        @log_base_dir = "/var/log"
      else
        @log_base_dir = "/var/log/#{@environment}"
      end
    end

    @application_instances = []
  end

  def add(config)
    block = eval("lambda {#{config}}")
    self.instance_eval(&block)
  end

  def application_instance(&hash)
    application_instance_config = DeployApp::ApplicationInstanceConfiguration.new(
      :app_base_dir => self.app_base_dir,
      :run_base_dir => self.run_base_dir,
      :log_base_dir => self.log_base_dir
    )
    application_instance_config.instance_eval(&hash)
    application_instance_config.apply_convention

    if (application_instance_config.type == "none")
      application_instance = DeployApp::ApplicationInstance.new(
        :application_instance_config => application_instance_config,
        :participation_service       => DeployApp::ParticipationService::Memory.new(:environment => @environment,
                                                                                    :application => application_instance_config.application,
                                                                                    :group       => application_instance_config.group
      ))
    else
      artifacts_dir = application_instance_config.artifacts_dir
      latest_jar = application_instance_config.latest_jar
      @artifact_resolver = DeployApp::ArtifactResolvers::CompositeArtifactResolver.new(
        :artifacts_dir    => artifacts_dir,
        :latest_jar       => latest_jar,
        :ssh_key_location => application_instance_config.ssh_key_location
      )

      @app_communicator = DeployApp::ApplicationCommunicator.new(
        :service_name => "#{@environment}-#{application_instance_config.application}-#{application_instance_config.group}",
        :config_file  => application_instance_config.config_filename
      )

      @participation_service = DeployApp::ParticipationService::Tatin.new(
        :environment => @environment,
        :application => application_instance_config.application,
        :group       => application_instance_config.group
      )

      application_instance = DeployApp::ApplicationInstance.new(
        :application_instance_config => application_instance_config,
        :application_communicator    => @app_communicator,
        :artifact_resolver           => @artifact_resolver,
        :participation_service       => @participation_service
      )

    end

    @application_instances << application_instance
  end

  def parse(dir = "/opt/deploytool-#{@environment}/conf.d/")
    if !File.exists?(dir)
      raise DeployApp::EnvironmentNotFound.new(dir)
    end

    Dir.entries(dir).each do |file|
      if file =~ /.cfg$/
        data = File.read("#{dir}/#{file}")
        add(data)
      end
    end

    self
  end

  attr_reader :application_instances

  def get_application_instance(spec)
    @application_instances.each do |instance|
      if instance.status[:application] == spec[:application] && instance.status[:group] == spec[:group]
        return instance
      end
    end
    raise DeployApp::NoInstanceFound.new(spec)
  end

  def status(spec = {})
    statuses = []
    @application_instances.each do |instance|
      statuses << instance.status
    end

    if !spec[:group].nil?
      statuses =  statuses.select { |status| status[:group] == spec[:group] }
    end
    if !spec[:application].nil?
      statuses =  statuses.select { |status|
        status[:application] == spec[:application]
      }

    end
    statuses
  end
end
