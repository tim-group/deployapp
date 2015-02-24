require 'deployapp/participation_service'
require 'net/http'

include DeployApp

class DeployApp::ParticipationService::Tatin < DeployApp::ParticipationService
  def initialize(args)
    @tatin_server = args[:tatin_server] || "http://127.0.0.1:5643"
    super(args)
  end

  def participating?
    "enabled" == get(url)
  end

  def enable_participation
    put(url, "enabled")
  end

  def disable_participation
    put(url, "disabled")
  end

  protected

  def url
    "#{@tatin_server}/#{@environment}/#{@application}/#{@group}"
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.get(uri.request_uri)
      return response.body
    end
  end

  def put(url, string)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.put(uri.request_uri, string)
      return response.body
    end
  end
end
