require 'deployapp/namespace'

class DeployApp::Coord
  attr_reader :name, :version, :type

  def initialize args
    @name    = args[:name]
    @version = args[:version]
    @type    = args[:type]
  end

  def string
    return "#{@name}-#{@version}.#{@type}"
  end

  def equal_to(other_coord)
    return other_coord.name==@name && other_coord.version==@version && other_coord.type==@type
  end
end

