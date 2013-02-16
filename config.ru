require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra/reloader' if development?

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require './natto'

run Sinatra::Application

