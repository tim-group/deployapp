require 'deployapp/namespace'
require 'deployapp/status'
require 'deployapp/util/log'
require 'net/http'

include DeployApp

class DeployApp::StatusRetriever
  include DeployApp::Util::Log

  def retrieve(base_url)
    status = DeployApp::Status.new(true)
    %w(stoppable version health).each { |n|
      status.add(n, get("#{base_url}/info/#{n}"))
    }
    return status
  rescue  Exception => e
    logger.error("Problem retrieving status: #{e.inspect}")
    logger.debug(e.backtrace)
    return DeployApp::Status.new(false)
  end

  def get(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, 'User-Agent' => 'deploytool health retriever').body
    end
  end
end
