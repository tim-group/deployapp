$: << File.join([File.dirname(__FILE__), "lib"])

require 'rubygems'
require 'rspec'
require 'mcollective'
require 'rspec/mocks'
require 'tempfile'

ENV['RACK_ENV'] = 'test'
