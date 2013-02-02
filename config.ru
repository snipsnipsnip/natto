require 'rubygems'
require 'bundler'

Bundler.require

require './natto'

run Sinatra::Application

