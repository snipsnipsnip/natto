#!/opt/local/bin/ruby
# coding: utf-8

# natto: a qiita hackathon 03 product

require 'slim'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static_assets'
require 'sinatra/config_file'

require_relative 'lib/dep_walker'

configure do
  config_file 'config.yml'
  set :sessions, {:key => 'z'}
end

helpers do
  def walk(reponame)
    # TODO: per-user auth
    dict = {}
    
    def dict.[](path)
      super.call
    end
    
    DepWalker.new(dict, settings.github_auth).walk(reponame)
  end
end

get '/' do
  slim :index
end

get '/walk' do
  content_type :json
  walk 'snipsnipsnip/natto'
end
