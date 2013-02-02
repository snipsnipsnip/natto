require_relative 'octowalker'
require_relative 'dep'

=begin
octowalkerとdepを使ってソースを読み込みつつ依存関係のグラフを作る。
=end
class DepWalker
  def walk(octowalker, reponame)
    sources = make_deferred_source_dict
    
    octowalker.each_blob(reponame) do |sha1, path, content_promise|
      # TODO: データベースなどにブロブをキャッシュ
      sources[path] = content_promise
    end
    
    dep_visitor = make_dep_visitor
    dep = Dep.new(@sources, dep_visitor)
    
    # TODO: make use of various options
    dep.run(sources.keys)
    
    {:nodes => dep_visitor.nodes, :links => dep_visitor.links}
  end
  
  private
  
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
