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
require_relative 'lib/cached_kit'

configure do
  config_file 'config.yml'
  set :sessions, {:key => 'z'}
end

helpers do
  def walk(reponame)
    # TODO: per-user auth
    DepWalker.new(source_cache, OctoWalker.new(cached_kit)).walk(reponame)
  end
  
  def cached_kit
    @cached_kit ||= CachedKit.new(sequel, Octokit::Client.new(settings.github_auth))
  end
  
  def source_cache
    @source_cache ||= SourceCache.new(sequel)
  end
  
  def sequel
    @sequel ||= begin
      db = Sequel.connect(settings.database_url)
      db.loggers << Logger.new(STDOUT) if settings.database_logging
      db
    end
  end
end

get '/' do
  slim :index
end

get '/:user/:repo/:commit' do |user, repo|
  user =~ /\A[\-_a-z\d]+\z/i and
    user =~ /\A[\-_a-z\d]+\z/i or
    not_found
  
  content_type :svg
  walk(user, repo)
end
