
require_relative 'dep'

=begin
octowalkerとdepを使ってソースを読み込みつつ依存関係のグラフを作る。
=end
class DepWalker
  # source_cache has a method [] : String -> String
  # source_cache has a method add : sha1 : String -> path : String -> content_promise : String
  def initialize(source_cache, octowalker)
    @sources = source_cache
    @octowalker = octowalker
  end
  
  def walk(reponame)
    files = []
    
    @octowalker.each_blob(reponame) do |sha1, path, content_promise|
      next unless path =~ /\.(?:c|cpp|h|hpp|rb|py|php|m|inc|pl|hxx|cxx|cc)/i
      @sources.add(sha1, path, content_promise)
      files << sha1
    end
    
    dep_visitor = make_dep_visitor
    
    with_graphviz do |f|
      dep = Dep.new(@sources, f)
      dep.run(files)
      f.close_write
      f.read
    end
  end
  
  private
  
  def with_graphviz
    IO.popen('dot -Tsvg', 'rb+') do |f|
      yield f
    end
  end
  
  def make_deferred_source_dict
    dict = {}
    
    def dict.[](path)
      super.call
    end
    
    dict
  end
  
  def make_dep_visitor
    DepVisitor.new([], [])
  end
  
  DepVisitor = Struct.new(:nodes, :links)
  
  class DepVisitor
    def node(nodename, node_label, source_files, fan_in, fan_out)
      nodes << nodename
    end
    
    def link(from_nodename, to_nodename)
      links << {:source => from_nodename, :target => to_nodename}
    end
  end
end
