require 'mcollective'
require 'deploy/namespace'
require 'util/namespace'

include Deploy

def setup_logger
  require 'util/composite_logger'
  require 'util/inmemory_logger'
  @remote_logger = Util::InMemoryLogger.new()
  Util::Log.set_logger(Util::CompositeLogger.new([logger,@remote_logger]))
end

module MCollective
  module Agent
    class Deployapp < RPC::Agent
      def process_instance(&block)
        spec = request
        process_host_configuration  do |host_configuration|
          instance = host_configuration.get_application_instance(spec)
          block.call(instance)
        end
      end

      def process_host_configuration(&block)
        begin
          require 'deploy/host_configuration'
          setup_logger()
          require 'util/log'
          extend ::Util::Log
          config_dir_prefix = config.pluginconf["deployapp.conf_dir_prefix"] || "/opt/deploytool"
          app_dir_prefix = config.pluginconf["deployapp.app_dir_prefix"] || "/opt/apps"
          spec = request
          environment = spec[:environment]
          config_dir = "#{config_dir_prefix}-#{environment}/conf.d"
          app_base_dir = "#{app_dir_prefix}-#{environment}"

          if (not File.exists?(config_dir))
            reply.data = nil
          else
            reply.data = {}
            host_configuration = Deploy::HostConfiguration.new(
              :app_base_dir=>app_base_dir,
              :environment=>environment)
            logger.debug("loading config from #{config_dir}")
            host_configuration.parse(config_dir)
            block.call(host_configuration)
          end
          reply.data[:successful] = true
        rescue Exception => e
          logger.error("AN ERROR OCCURED: #{e.inspect}")
          logger.debug(e.backtrace)
          reply.data[:successful] = false
        ensure
          reply.data[:logs] = @remote_logger.logs()
        end
      end

      action "status" do
        spec = request
        process_host_configuration  do |host_configuration|
          logger.debug("requested status for spec: #{spec}")
          status = host_configuration.status(spec)
          logger.debug("found #{status.size} application instances")
          logger.debug("#{status.to_yaml}")
          reply.data = {:statuses=>status}
        end
      end

      action "update_to_version" do
        version = request[:version]
        logger.debug("recieved message to update key #{request} to version #{version}")

        process_instance do |instance|
          instance.disable_participation()
          instance.update_to_version(version)
        end
      end

      action "enable_participation" do
        process_instance do |instance|
          logger.debug("recieved message to enable participation for spec #{spec}")
          instance.enable_participation()
        end
      end

      action "disable_participation" do
        process_instance do |instance|
          logger.debug("recieved message to disable participation for spec #{spec}")
          instance.disable_participation()
        end
      end
    end
  end
end
