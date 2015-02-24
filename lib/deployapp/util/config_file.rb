require 'deployapp/util/namespace'
require 'deployapp/util/log'

class DeployApp::Util::ConfigFile
  include DeployApp::Util::Log
  def initialize(filename)
    @filename = filename
    @properties = {}
    begin
      IO.foreach(filename) do |line|
        @properties[Regexp.last_match(1).strip] = Regexp.last_match(2) if line =~ /([^=]*)=(.*)\/\/(.*)/ || line =~ /([^=]*)=(.*)/
      end
    rescue
      logger.error("ERROR Reading file #{filename} \n")
    end
  end

  def get(property)
    @properties[property]
  end

  def port
    return @properties["port"].strip if !@properties["port"].nil?
  end
end
