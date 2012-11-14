require 'util/namespace'
require 'deploy/host_configuration'
require 'optparse'
require 'yaml'

class Util::OptionParser
  class StatusRequest
    def required
      return [:environment]
    end

    def execute(options)
      host_configuration = Deploy::HostConfiguration.new(:environment=>options[:environment])
      host_configuration.parse("/opt/deploytool-#{options[:environment]}/conf.d/")
      status = host_configuration.status(options)
      print status.to_yaml
    end
  end

  class InstallRequest
    def required
      return [:environment,:application,:group,:version]
    end

    def execute(options)
      host_configuration = Deploy::HostConfiguration.new(:environment=>options[:environment])
      host_configuration.parse("/opt/deploytool-#{options[:environment]}/conf.d/")
      instance = host_configuration.get_application_instance(options)
      instance.disable_participation()
      instance.update_to_version(options[:version])
    end
  end

  class DisableParticipationRequest
    def required
      return [:environment,:application,:group]
    end

    def execute(options)
      print "Disabling participation\n\n"
      host_configuration = Deploy::HostConfiguration.new(:environment=>options[:environment])
      host_configuration.parse("/opt/deploytool-#{options[:environment]}/conf.d/")
      instance = host_configuration.get_application_instance(options)
      instance.disable_participation()
    end
  end

  class EnableParticipationRequest
    def required
      return [:environment,:application,:group]
    end

    def execute(options)
      print "Enabling participation\n\n"
      host_configuration = Deploy::HostConfiguration.new(:environment=>options[:environment])
      host_configuration.parse("/opt/deploytool-#{options[:environment]}/conf.d/")
      instance = host_configuration.get_application_instance(options)
      instance.enable_participation()
    end
  end

  def initialize()
    @options = {}
    @commands = []
    @option_parser = OptionParser.new do |opts|
      opts.banner =
"Usage:
    manage --environment=staging --show-status
    manage --environment=staging --application=JavaHttpRef --group=blue --enable-participation
    manage --environment=staging --application=JavaHttpRef --group=blue --disable-participation
    manage --environment=staging --application=JavaHttpRef --group=blue --versio=2.21.0 --install

"

      opts.on("-e","--environment ENVIRONMENT", "specify the environment to execute the plan") do
        |env|
        @options[:environment] = env
      end
      opts.on("-a","--application APPLICATION", "specify the application to execute the plan for") do    |app|
        @options[:application] = app
      end
      opts.on("-g","--group GROUP", "specify the group to execute the plan for") do    |app|
        @options[:group] = app
      end
      opts.on("-v","--version VERSION", "specify the version to deploy") do    |app|
        @options[:version] = app
      end
      opts.on("-s","--show-status", "displays the status for instances on this host") do
        @commands << StatusRequest.new()
      end
      opts.on("-i","--install", "install a new version to an instance on this host") do
        @commands << InstallRequest.new()
      end
      opts.on("-p","--enable-participation", "enables load balancer participation for the given instance") do
        @commands << EnableParticipationRequest.new()
      end
      opts.on("-n","--disable-participation", "disables load balancer participation for the given instance") do
        @commands << DisableParticipationRequest.new()
      end
    end
  end

  def check_required(required)
    required.each do |option|
      if @options[option].nil?
        print @option_parser.help()
        exit(1)
      end
    end
  end

  def parse
    @option_parser.parse!
    @commands.each do |command|
      check_required(command.required())
    end

    if @commands.size==0
      print @option_parser.help()
      exit(1)
    end

    @commands.each do |command|
      command.execute(@options)
    end
  end
end
