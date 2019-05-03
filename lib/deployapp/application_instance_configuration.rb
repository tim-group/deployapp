require 'deployapp/namespace.rb'

class DeployApp::ApplicationInstanceConfiguration
  attr_reader :home, :config_filename, :artifacts_dir, :latest_jar, :artifactresolver

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

  def artifactresolver(artifactresolver = @artifactresolver)
    @artifactresolver = artifactresolver
    @artifactresolver
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
    @home = "#{@app_base_dir}/#{@application}-#{@group}" if @home.nil?
    @config_filename = "#{@home}/config.properties" if @config_filename.nil?
    @artifacts_dir = "#{@home}/artifacts" if @artifacts_dir.nil?

    @latest_jar = "#{@artifacts_dir}/#{@application}" if @latest_jar.nil?
  end
end
