$: << File.join(File.dirname(__FILE__), "..", "../lib")

require 'deploy/status'
require 'deploy/status_retriever'
require 'socket'
require 'net/http'
require 'test/unit'

class StatusParserTest < Test::Unit::TestCase
  def runAgainstServer responses, &block
    server = TCPServer.new(2002)
    @serverthread =  Thread.new {
      while(true)
        client = server.accept
        begin
          req = client.recv(100)
          regex = Regexp.new(/GET (.+) HTTP/)
          resp = "nodata"
          urimatch= regex.match(req)
          if  urimatch
            uri = urimatch[1]
            if (not responses[uri].nil?)
              resp = responses[uri]
            end
          end

          headers = ["HTTP/1.1 200 OK",
            "Date: Tue, 14 Dec 2010 10:48:45 GMT",
            "Server: Ruby",
            "Content-Type: text/html; charset=iso-8859-1",
            "Content-Length: #{resp.length}\r\n\r\n"].join("\r\n")

          client.puts headers
          client.puts resp
          client.close
        rescue e
        end
      end
    }
    begin
      block.call()
    ensure
      server.close
      @serverthread.kill
    end
  end

  def test_retrieves_version
    runAgainstServer({"/info/version"=>"0.0.1.65"}) {
      retriever=Deploy::StatusRetriever.new()
      assert_equal "0.0.1.65", retriever.retrieve("http://localhost:2002").version
    }
  end

  def test_retrieves_health
    runAgainstServer({"/info/health"=>"ill"}) {
      retriever=Deploy::StatusRetriever.new()
      assert_equal "ill", retriever.retrieve("http://localhost:2002").health
    }
  end

  def test_stoppable_when_safe
    runAgainstServer({"/info/stoppable"=>"safe"}) {
      retriever=Deploy::StatusRetriever.new()
      assert retriever.retrieve("http://localhost:2002").stoppable?
    }
  end

  def test_not_stoppable_when_unwise
    runAgainstServer({"/info/stoppable"=>"unwise"}) {
      retriever=Deploy::StatusRetriever.new()
      assert ! retriever.retrieve("http://localhost:2002").stoppable?
    }
  end

end
