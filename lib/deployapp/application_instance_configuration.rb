require 'deployapp/namespace.rb'

class DeployApp::ApplicationInstanceConfiguration
  attr_reader :home, :config_filename, :artifacts_dir, :latest_jar

  def initialize(args = {})
    @app_base_dir = args[:app_base_dir]
    @run_base_dir = args[:run_base_dir]
    @log_base_dir = args[:log_base_dir]
    @cluster = "default"
  end

  def application(application = @application)
    @application = application
    @application
  end

  def group(group = @group)
    @group = group
    @group
  end

  def cluster(cluster = @cluster)
    @cluster = cluster
    @cluster
  end

  def type(type = @type)
    @type = type
    @type
  end

  def additional_jvm_args(additional_jvm_args = @additional_jvm_args)
    @additional_jvm_args = additional_jvm_args
    @additional_jvm_args
  end

  def ssh_key_location
    "/root/.ssh/productstore"
  end

  def run_as_user
    @application.downcase
  end

  def apply_convention
    if @home.nil?
      @home = "#{@app_base_dir}/#{@application}-#{@group}"
    end
    if @config_filename.nil?
      @config_filename = "#{@home}/config.properties"
    end
    if @artifacts_dir.nil?
      @artifacts_dir = "#{@home}/artifacts"
    end

    if @latest_jar.nil?
      @latest_jar = "#{@artifacts_dir}/#{@application}"
    end
  end
end
