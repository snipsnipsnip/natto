#!/opt/local/bin/ruby
# coding: utf-8

# natto: a qiita hackathon 03 product

require 'slim'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/static_assets'
require 'sinatra/config_file'

require 'natto/dep_walker'
require 'natto/repo'

configure do
  config_file 'config.yml'
  
  unless settings.respond_to?(:git_binary)
    set :git_binary, 'git'
  end

  unless settings.respond_to?(:repos_dir)
    set :repos_dir, File.join(settings.root, 'tmp', 'repos')
  end
end

class MemorySourceCache
  def initialize
    @paths = {}
    @contents = {}
  end

  def add(sha1, path, promise)
    @paths[sha1] = path
    @contents[sha1] = promise
  end
  
  def [](sha1)
    src = @contents.fetch(sha1)
    if src.respond_to?(:call)
      @contents[sha1] = src.call
    else
      src
    end
  end
  
  def path_of(sha1)
    @paths.fetch(sha1)
  end
end

helpers do
  def walk(reponame)
    # TODO: per-user auth
    DepWalker.new(source_cache, Repo.new(settings.git_binary, settings.repos_dir)).walk(reponame)
  end
  
  def source_cache
    @source_cache ||= MemorySourceCache.new
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

get '/:user/:repo' do |user, repo|
  user =~ /\A[\-_a-z\d]+\z/i and
    repo =~ /\A[\-_a-z\d]+\z/i or
    not_found
  
  content_type :svg
  walk("#{user}/#{repo}")
end
