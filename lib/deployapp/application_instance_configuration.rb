require 'deployapp/namespace.rb'

class DeployApp::ApplicationInstanceConfiguration
  attr_reader :home, :config_filename, :artifacts_dir, :latest_jar

  def initialize(args={})
    @app_base_dir = args[:app_base_dir]
    @run_base_dir = args[:run_base_dir]
    @log_base_dir = args[:log_base_dir]
  end

  def application(application = @application)
    @application = application
    return @application
  end

  def artifact(artifact = @artifact)
    @artifact = artifact
    return @artifact
  end

  def group(group = @group)
    @group = group
    return @group
  end

  def type(type = @type)
    @type = type
    return @type
  end

  def additional_jvm_args(additional_jvm_args = @additional_jvm_args)
    @additional_jvm_args=additional_jvm_args
    return @additional_jvm_args
  end

  def ssh_key_location
    return  "/root/.ssh/productstore"
  end

  def run_as_user
    return @artifact.downcase
  end

  def apply_convention
    if (@artifact== nil)
      @artifact = @application
    end
    if (@home == nil)
      @home = "#{@app_base_dir}/#{@artifact}-#{@group}"
    end
    if (@config_filename == nil)
      @config_filename = "#{@home}/config.properties"
    end
    if (@artifacts_dir == nil)
      @artifacts_dir= "#{@home}/artifacts"
    end

    if (@latest_jar == nil)
      @latest_jar = "#{@artifacts_dir}/#{@artifact}"
    end
  end
end

