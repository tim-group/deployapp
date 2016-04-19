$: << File.join(File.dirname(__FILE__), '..', '../lib')
require 'deployapp/util/config_file'

describe DeployApp::Util::ConfigFile do
  it 'can_parse_file' do
    config = 'port=2003'
    config_file = File.new('build/test.config.properties', 'w')
    config_file.write(config)
    config_file.close
    parser =  DeployApp::Util::ConfigFile.new('build/test.config.properties')
    parser.port.should eq('2003')
  end
end
