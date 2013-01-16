require 'deploy/namespace'
require 'deploy/application_instance_configuration'
require 'deploy/application_instance'
require 'deploy/product_store_artifact_resolver'
require 'deploy/application_communicator'
require 'deploy/tatin_participation_service'

class Deploy::HostConfiguration
  attr_reader :app_base_dir, :run_base_dir, :log_base_dir

  def initialize( args = {:environment => ""} )
    @environment  = args[:environment]
    @app_base_dir = args[:app_base_dir]
    @run_base_dir = args[:run_base_dir]
    @log_base_dir = args[:log_base_dir]

    if (@app_base_dir == nil)
      if (@environment == "")
        @app_base_dir = "/opt/apps#{@environment}"
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
    application_instance_config = Deploy::ApplicationInstanceConfiguration.new(
      :app_base_dir => self.app_base_dir,
      :run_base_dir => self.run_base_dir,
      :log_base_dir => self.log_base_dir
    )
    application_instance_config.instance_eval(&hash)
    application_instance_config.apply_convention()

    if (application_instance_config.type() == "none")
      application_instance = Deploy::ApplicationInstance.new(
        :application_instance_config => application_instance_config,
        :participation_service       => MemoryParticipationService.new
      )
    else
      artifacts_dir = application_instance_config.artifacts_dir()
      latest_jar = application_instance_config.latest_jar()
      @artifact_resolver = Deploy::ProductStoreArtifactResolver.new(
        :artifacts_dir    => artifacts_dir,
        :latest_jar       => latest_jar,
        :ssh_key_location => application_instance_config.ssh_key_location
      )

      @app_communicator = Deploy::ApplicationCommunicator.new(
        :service_name => "#{@environment}-#{application_instance_config.application}-#{application_instance_config.group}",
        :config_file  => application_instance_config.config_filename
      )

      @participation_service = Deploy::TatinParticipationService.new(
        :environment => @environment,
        :application => application_instance_config.application,
        :group       => application_instance_config.group
      )

      application_instance = Deploy::ApplicationInstance.new(
        :application_instance_config => application_instance_config,
        :application_communicator    => @app_communicator,
        :artifact_resolver           => @artifact_resolver,
        :participation_service       => @participation_service
      )

    end

    @application_instances << application_instance
  end

  def parse(dir="/opt/deploytool-#{@environment}/conf.d/")

    if (not File.exists?(dir))
      raise Deploy::EnvironmentNotFound.new(dir)
    end

    Dir.entries(dir).each do |file|
      if (file =~ /.cfg$/)
        data = File.read("#{dir}/#{file}")
        add(data)
      end
    end

    self
  end

  def application_instances()
    return @application_instances
  end

  def get_application_instance(spec)
    @application_instances.each do |instance|
      if (instance.status[:application]==spec[:application] and instance.status[:group] == spec[:group])
        return instance
      end
    end
    raise Deploy::NoInstanceFound.new(spec)
  end

  def status( spec = {} )
    statuses = []
    @application_instances.each do |instance|
      statuses << instance.status()
    end

    if (spec[:group]!=nil)
      statuses =  statuses.select { |status| status[:group]==spec[:group] }
    end
    if (spec[:application]!=nil)
      statuses =  statuses.select { |status|
        status[:application]==spec[:application]
      }

    end
    return statuses
  end

end
