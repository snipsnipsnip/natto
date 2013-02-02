require 'set'

=begin
ソースをスキャンして中の文章から依存関係を（本当に）適当に推測する。
やっつけスクリプトから移植したので若干つくりが変。
TODO: きちんと依存関係とかの名詞にする
=end
class Dep
  attr_accessor :ignore_file_matcher
  attr_accessor :source_code_filters
  attr_accessor :case_sensitive
  attr_accessor :cluster

  # sources has a method [] : (path : String) -> String
  def initialize(sources, out)
    @io = out
    @ignore_file_matcher = nil
    @source_code_filters = []
    @case_sensitive = false
    @cluster = false
    @sources = sources
  end

  def run(source_paths)
    graph = scan(@source_code_filters, @case_sensitive, list(source_paths, @ignore_file_matcher))
    print_flat(graph)
  end
  
  private
  
  def list(source_paths, ignore)
    source_paths.reject {|x| ignore === x }
  end

  def read_source(filename)
    @sources[filename]
  end

  def scan(gsub, case_sensitive, sources)
    labels = sources.map {|x| calc_label x }
    nodenames = sources.map {|x| calc_nodename x }
    
    patterns = labels.map {|n| Regexp.escape(n).gsub('_', '_?') }.sort_by {|n| -n.size }
    pattern = Regexp.new("\\b(?:#{patterns.join('|')})", !case_sensitive)
    
    tree = {}
    sources.zip(nodenames, labels) do |filename, nodename, label|
      source = read_source(filename)
      gsub.each {|from, to| source.gsub!(from, to) }
      
      node = (tree[nodename] ||= make_node(label, filename))
      node.files << filename
      source.scan(pattern) {|s| node.links << calc_nodename(s) }
      node.links.delete(nodename)
    end
    
    tree
  end
  
  Node = Struct.new(:label, :files, :links, :cluster)
  
  def make_node(label, filename)
    Node.new(label, [], Set.new, calc_cluster_name(filename))
  end
  
  def calc_cluster_name(filename)
    File.basename(File.dirname(filename))
  end
  
  def calc_label(filepath)
    File.basename(filepath, '.*')
  end
  
  def calc_nodename(filepath)
    calc_label(filepath).downcase.gsub('_', '')
  end
  
  def calc_cluster(dep)
    dep.group_by {|k,v| v.cluster }
  end
  
  def print_cluster(graph, clusters)
    links = {}
    outer_links = Set.new
    
    graph.each do |nodename, node|
      node.links.each do |destname|
        if clusters[node.cluster].any? {|n, _| n == destname }
          (links[node.cluster] ||= Set.new) << [nodename, destname]
        else
          outer_links << [nodename, destname]
        end
      end
    end
    
    print_digraph do
      indent = '    '
    
      links.each_with_index do |(cluster_name, links), i|
        print_subgraph(i, cluster_name) do
          clusters[cluster_name].each do |name, node|
            print_node(graph, name, node, indent)
          end
          
          links.each {|from, to| print_link(from, to, indent) }
        end
      end
      
      indent = '  '      
      outer_links.each {|from, to| print_link(from, to, indent) }
    end
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
  
  def print_subgraph(number, label)
    @io.puts "  subgraph cluster#{number} {"
    @io.puts "    label = #{label.inspect};"
    @io.puts %{   fontcolor = "#123456"; fontsize = 30; fontname="Arial, Helvetica";}
    
    yield
    
    @io.puts "  }"
  end
  
  def print_link(from, to, indent=nil)
    @io.puts %{#{indent}"#{from}" -> "#{to}";} if from != to
  end
  
  def print_node(graph, node_name, node, indent=nil)
    node.files.each {|f| @io.puts %{#{indent}/* #{f} */} }
    fan_in = graph.count {|n,d| d.links.include?(node_name) }
    fan_out = node.links.size
    @io.puts %{#{indent}"#{node_name}" [label = "#{node.label}|{#{fan_in} in|#{fan_out} out}", shape = Mrecord];}
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
