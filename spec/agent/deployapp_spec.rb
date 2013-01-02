require 'spec_helper'

describe 'deployapp' do

  before do
    agent_file = File.join([File.dirname(__FILE__)], '../../lib/agent/Deployapp.rb')
    #@agent = MCollective::Test::LocalAgentTest.new("deployapp", :agent_file=> agent_file).plugin
    #@agent.config.pluginconf['deployapp.conf_dir_prefix'] = File.expand_path "#{File.dirname(__FILE__)}/../fixtures/"
    #@agent.config.pluginconf['deployapp.app_dir_prefix'] = File.expand_path "#{File.dirname(__FILE__)}/../fixtures/"
  end

  it 'returns statuses when it finds instances' do
    #result = @agent.call(:status,:environment=>"test")
    #result[:data][:statuses].size.should eq(1)
    #result[:data][:logs].size.should be >0
  end

  it 'simply ignores the request if this agent has nothing to show' do
    #result = @agent.call(:status,:environment=>"myx5")
    #result[:data].should eq(nil)
  end

  it 'updates the version of my app - and indicates failure' do
    #result = @agent.call(:update_to_version,:environment=>"test", :application=>"testxy",:group=>"blue", :version=>4)
    #result[:data][:logs][:errors].size.should be >0
    #result[:data][:successful].should eql(false)
  end

end
