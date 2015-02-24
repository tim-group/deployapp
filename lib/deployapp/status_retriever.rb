require 'deployapp/namespace'
require 'deployapp/status'
require 'net/http'

include DeployApp

class DeployApp::StatusRetriever
  def retrieve(base_url)
    begin
      status = DeployApp::Status.new(true)
      %w(stoppable version health).each { |n|
        status.add(n, get("#{base_url}/info/#{n}"))
      }
      return status
    rescue  Exception
      return DeployApp::Status.new(false)
    end
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, 'User-Agent' => 'deploytool health retriever').body
    end
  end
end
