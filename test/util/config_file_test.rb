$: << File.join(File.dirname(__FILE__), "..", "../lib")
require 'test/unit'
require 'deployapp/util/config_file'

class ConfigFileParserTest  < Test::Unit::TestCase
  def test_can_parse_file
    config = %[port=2003]
    config_file=File.new("build/test.config.properties", "w")
    config_file.write(config)
    config_file.close
    parser =  DeployApp::Util::ConfigFile.new("build/test.config.properties")
    assert_equal "2003", parser.port
  end

end
