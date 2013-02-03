#!/opt/local/bin/ruby
# coding: utf-8

# natto: a qiita hackathon 03 product

require 'slim'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static_assets'
require 'sinatra/config_file'

require_relative 'lib/dep_walker'
require_relative 'lib/source_cache'

configure do
  config_file 'config.yml'
  set :sessions, {:key => 'z'}
end

helpers do
  def walk(reponame)
    # TODO: per-user auth
    dict = SourceCache.new(sequel)
    DepWalker.new(dict, settings.github_auth).walk(reponame)
  end
  
  def sequel
    @sequel ||= begin
      db = Sequel.connect(settings.database_url)
      db.loggers << Logger.new(STDOUT) if settings.database_logging
      
      db.create_table?(:source) do
        String :sha1
        String :content
      end
      
      db
    end
  end
end

get '/' do
  slim :index
end

get '/walk' do
  content_type :gif
  walk 'snipsnipsnip/natto'
end
