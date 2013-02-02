require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra/reloader' if development?

require './natto'

run Sinatra::Application

