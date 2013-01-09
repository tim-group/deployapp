require 'deploy/namespace'
require 'net/http'

include Deploy

class Deploy::TatinParticipationService
  def initialize(args)
    @tatin_server = args[:tatin_server] || "http://localhost:5643"
    @environment = args[:environment] || "default"
    @application = args[:application] || "default"
    @group = args[:group] || "default"
  end

  def url()
    return "#{@tatin_server}/#{@environment}/#{@application}/#{@group}"
  end

  def participating()
    return "enabled"==get(url())
  end

  def enable_participation()
    put(url(),"enabled")
  end

  def disable_participation()
    put(url(),"disabled")
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.get(uri.request_uri)
      return response.body
    end
  end

  def put(url,string)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.put(uri.request_uri, string)
      return response.body
    end
  end
end

