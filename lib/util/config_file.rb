require 'util/namespace'
require 'util/log'

class Util::ConfigFile
  include Util::Log
  def initialize(filename)
    @filename = filename
    @properties = {}
    begin
      IO.foreach(filename) do |line|
        @properties[$1.strip] = $2 if line =~ /([^=]*)=(.*)\/\/(.*)/ || line =~ /([^=]*)=(.*)/
      end
    rescue
      logger.error("ERROR Reading file #{filename} \n")
    end
  end

  def get(property)
    @properties[property] || raise("No #{property} property found in #{@filename}")
  end

  def port
    get('port')
  end
end
