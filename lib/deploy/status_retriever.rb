require 'deploy/namespace'
require 'deploy/status'
require 'net/http'

include Deploy

class Deploy::StatusRetriever
  def retrieve(base_url)
    begin
      status = Deploy::Status.new(true)
      status.add("stoppable", get("#{base_url}/info/stoppable"))
      status.add("version", get("#{base_url}/info/version"))
      return status
    rescue  Exception
      return Deploy::Status.new(false)
    end
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.get(uri.request_uri)
      return response.body
    end
  end
end
