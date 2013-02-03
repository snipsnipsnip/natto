require 'graphviz'
require 'stringio'
require_relative 'octo_walker'
require_relative 'dep'

=begin
octowalkerとdepを使ってソースを読み込みつつ依存関係のグラフを作る。
=end
class DepWalker
  # source_cache has a method [] : String -> String
  # source_cache has a method add : sha1 : String -> path : String -> content_promise : String
  def initialize(source_cache, octowalker_or_options)
    @sources = source_cache
    @octowalker = octowalker_or_options.respond_to?(:each_blob) ? octowalker_or_options : OctoWalker.new(octowalker_or_options)
  end
  
  def walk(reponame)
    @octowalker.each_blob(reponame) do |sha1, path, content_promise|
      @sources.add(sha1, path, content_promise)
    end
    
    out = StringIO.new
    dep_visitor = DepDot.new(out)
    dep = Dep.new(@sources, dep_visitor)
    dep.header
    dep.run(@sources.keys)
    dep.footer
    
    dot = out.to_s
    
    {:image => render_graph(dot), :map => make_map(dot)}
  end
  
  private
  
  def render_graph(graph)
    with_graphviz('-Tgif') do |f|
      dot = DepDot.new(f)
      dot.header
      graph.nodes.each {|*a| dot.node *a }
      graph.links.each {|*a| dot.link *a }
      dot.footer
      
      f.close_write
      f.read
    end
  end
  
  def make_map(graph)
  end
  
  def graphviz(opt, graph)
    with_graphviz(opt) do |f|
      dot = DepDot.new(f)
      dot.header
      graph.nodes.each {|*a| dot.node *a }
      graph.links.each {|*a| dot.link *a }
      dot.footer
      
      f.close_write
      f.read
    end
  end
  
  def with_graphviz(opt)
    IO.popen("dot #{opt}", 'rb+') do |f|
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
    DepCollector.new([], [])
  end
  
  DepCollector = Struct.new(:nodes, :links)
  
  class DepCollector
    def node(nodename, node_label, source_files, fan_in, fan_out)
      nodes << nodename
    end
    
    def link(from_nodename, to_nodename)
      links << {:source => from_nodename, :target => to_nodename}
    end
  end
  
  class DepDot
    def initialize(io)
      @io = io
    end
    
    def node(from, to)
      @io.puts %{#{from}" -> "#{to}";}
    end
    
    def node(node_name, node_label, node_files, fan_in, fan_out)
      node_files.each {|f| @io.puts %{/* #{f} */} }
      @io.puts %{"#{node_name}" [label = "#{node_label}|{#{fan_in} in|#{fan_out} out}", shape = Mrecord];}
    end
    
    def header
      @io.puts '// try tred tool of graphviz if you want simpler (transitively reduced) graph'
      @io.puts 'digraph {'
      @io.puts '  overlap = false;'
      @io.puts '  rankdir = LR;'
      @io.puts '  node [style = filled, fontcolor = "#123456", fillcolor = white, fontsize = 30, fontname="Arial, Helvetica"];'
      @io.puts '  edge [color = "#661122"];'
      @io.puts '  bgcolor = "transparent";'
    end
    
    def footer
      @io.puts '}'
    end
  end
end
