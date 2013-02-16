require 'set'

=begin
ソースをスキャンして中の文章から依存関係を（本当に）適当に推測する。
やっつけスクリプトから移植したので若干つくりが変。
TODO: きちんと依存関係とかの名詞にする
=end
class Dep
  attr_accessor :source_code_filters
  attr_accessor :case_sensitive
  attr_accessor :cluster

  # sources has a method [] : (path : String) -> String
  def initialize(sources, out)
    @io = out
    @source_code_filters = []
    @case_sensitive = false
    @cluster = false
    @sources = sources
  end

  def run(source_ids)
    graph = scan(@source_code_filters, @case_sensitive, source_ids)
    print_flat(graph)
  end
  
  private
  
  def read_source(sha)
    @sources[sha]
  end
  
  def get_filepath(sha)
    @sources.path_of(sha)
  end

  def scan(gsub, case_sensitive, sources)
    labels = sources.map {|x| calc_label get_filepath(x) }
    nodenames = sources.map {|x| calc_nodename get_filepath(x) }
    
    patterns = labels.map {|n| Regexp.escape(n).gsub('_', '_?') }.sort_by {|n| -n.size }
    pattern = Regexp.new("\\b(?:#{patterns.join('|')})", !case_sensitive)
    
    tree = {}
    sources.zip(nodenames, labels) do |source_id, nodename, label|
      source = read_source(source_id)
      gsub.each {|from, to| source.gsub!(from, to) }
      
      node = (tree[nodename] ||= make_node(label, source_id))
      node.files << source_id
      source.scan(pattern) {|s| node.links << calc_nodename(s) }
      node.links.delete(nodename)
    end
    
    tree
  end
  
  Node = Struct.new(:label, :files, :links, :id)
  
  def make_node(label, sha)
    Node.new(label, [], Set.new, sha)
  end
  
  def calc_label(filename)
    File.basename(filename, '.*')
  end
  
  def calc_nodename(filename)
    calc_label(filename).downcase.gsub('_', '')
  end

  def print_flat(dep)
    print_digraph do
      @io.puts
      @io.puts '  // nodes'
      indent = '  '
      
      dep.each do |node_name, node|
        print_node(dep, node_name, node, indent)
      end
      
      @io.puts
      @io.puts '  // links'
      
      dep.each do |s, node|
        node.links.each do |d|
          print_link s, d, indent
        end
      end
    end
  end
  
  def print_link(from, to, indent=nil)
    @io.puts %{#{indent}"#{from}" -> "#{to}";} if from != to
  end
  
  def print_node(graph, node_name, node, indent=nil)
    node.files.each {|f| @io.puts %{#{indent}/* #{f} */} }
    fan_in = graph.count {|n,d| d.links.include?(node_name) }
    fan_out = node.links.size
    @io.puts %{#{indent}"#{node_name}" [id="#{node.id}", label="#{node.label}|{#{fan_in} in|#{fan_out} out}", shape = Mrecord];}
  end
  
  def print_digraph
    @io.puts '// try tred tool of graphviz if you want simpler (transitively reduced) graph'
    @io.puts 'digraph {'
    @io.puts '  overlap = false;'
    @io.puts '  rankdir = LR;'
    @io.puts '  node [style = filled, fontcolor = "#123456", fillcolor = white, fontsize = 30, fontname="Arial, Helvetica"];'
    @io.puts '  edge [color = "#661122"];'
    @io.puts '  bgcolor = "transparent";'
    
    yield
    
    @io.puts '}'
  end
end

Dep.main if $0 == __FILE__
