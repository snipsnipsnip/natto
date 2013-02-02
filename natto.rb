#!/opt/local/bin/ruby
# coding: utf-8

# natto: a qiita hackathon 03 product

require 'slim'
require 'sass'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static_assets'
require 'sinatra/config_file'
require 'sequel'

require_relative 'lib/octowalker'

configure do
  config_file 'config.yml'
  set :sessions, {:key => 'z'}
end

helpers do
  def github
    # TODO: per-user auth
    @github ||= OctoWalker.new(settings.github_auth)
  end
end

get '/' do
  slim :index
end
