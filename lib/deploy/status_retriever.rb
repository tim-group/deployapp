require 'deploy/namespace'
require 'deploy/status'
require 'net/http'

include Deploy

class Deploy::StatusRetriever
  def retrieve(base_url)
    begin
      status = Deploy::Status.new(true)
      ['stoppable', 'version', 'health'].each { |n|
        status.add(n, get("#{base_url}/info/#{n}"))
      }
      return status
    rescue  Exception
      return Deploy::Status.new(false)
    end
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, {'User-Agent' => 'deploytool health retriever'}).body
    end
  end
end

