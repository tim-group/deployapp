require 'mcollective'
require 'deploy/namespace'
require 'util/namespace'

include Deploy
include Util

def setup_logger
  require 'util/composite_logger'
  require 'util/inmemory_logger'
  @remote_logger = Util::InMemoryLogger.new()
  Util::Log.set_logger(Util::CompositeLogger.new([logger,@remote_logger]))
end

module MCollective
  module Agent
    class Deployapp < RPC::Agent
      action "status" do
        begin
          require 'deploy/host_configuration'
          setup_logger()

          spec = request[:spec]
          environment = spec[:environment]
          host_configuration = Deploy::HostConfiguration.new(:environment=>environment)
          logger.debug("loading config from: /opt/deploytool-#{environment}/conf.d/")
          host_configuration.parse("/opt/deploytool-#{environment}/conf.d/")
          logger.debug("requested status for spec: #{spec}")
          status = host_configuration.status(spec)
          logger.debug("found #{status.size} application instances")
          logger.debug("#{status.to_yaml}")
          reply.data = status
        rescue Exception => msg
          logger.error("AN ERROR OCCURED whilst attempting to retrieve status: #{msg}")
          logger.error(msg.backtrace)
        end
      end

      action "update_to_version" do
        begin
          require 'deploy/host_configuration'
          setup_logger()

          # N.B. Everything used to be passed in a hash inside the request called
          # :spec - this is not awesome, as it means that you can't use mco rpc
          # on the command line at all (as you can't input a hash from the command
          # line), and also means that you can't validate anything in the DDL
          spec = request[:spec] || request
          environment = spec[:environment]
          version = request[:version]

          logger.debug("recieved message to update key #{spec} to version #{version}")
          host_configuration = Deploy::HostConfiguration.new(:environment=>environment)
          host_configuration.parse("/opt/deploytool-#{environment}/conf.d/")
          instance = host_configuration.get_application_instance(spec)
          instance.disable_participation()
          instance.update_to_version(version)
        rescue Exception => msg
          logger.error("AN ERROR OCCURED whilst attempting to update: #{msg}")
          logger.error(msg.backtrace)
        ensure
          reply.data = {
            :logs=>  @remote_logger.logs()
          }
        end
      end

      action "enable_participation" do
        begin
          require 'deploy/host_configuration'
          setup_logger()

          spec = request[:spec]
          environment = spec[:environment]
          logger.debug("recieved message to enable participation for spec #{spec}")
          host_configuration = Deploy::HostConfiguration.new(:environment=>environment)
          host_configuration.parse("/opt/deploytool-#{environment}/conf.d/")
          instance = host_configuration.get_application_instance(spec)
          instance.enable_participation()

        rescue Exception => msg
          logger.error("AN ERROR OCCURED whilst attempting to enable participation: #{msg}")
          logger.error(msg.backtrace)
        ensure
          reply.data = {
            :logs=>  @remote_logger.logs()
          }
        end
      end

      action "disable_participation" do
        begin
          require 'deploy/host_configuration'
          setup_logger()

          spec = request[:spec]
          environment = spec[:environment]
          logger.debug("recieved message to disable participation for spec #{spec}")
          host_configuration = Deploy::HostConfiguration.new(:environment=>environment)
          host_configuration.parse("/opt/deploytool-#{environment}/conf.d/")
          instance = host_configuration.get_application_instance(spec)
          instance.disable_participation()
        rescue Exception => msg
          logger.error("AN ERROR OCCURED whilst attempting to disable participation: #{msg}")
          logger.error(msg.backtrace)
        ensure
          reply.data = {
            :logs=>  @remote_logger.logs()
          }
        end
      end
    end
  end
end
