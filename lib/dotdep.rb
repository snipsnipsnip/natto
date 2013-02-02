@ruby -x "%~f0" %* & exit /b
#!/usr/bin/ruby -Ku
require 'optparse'
require 'set'

class Dep
  def self.main(argv=ARGV)
    dep = new
    froms = []
    tos = []
    
    OptionParser.new do |o|
      o.banner += " source-file.."
      
      o.on('-i REGEXP', '--ignore', 'ignore files') do |arg|
        dep.ignore_file_matcher and warn "warning: overwriting ignore expression; you should use |"
        dep.ignore_file_matcher = Regexp.new(arg)
      end
      
      o.on('-s REGEXP', '--gsub-from', 'filter source code like s///g (from part)') do |arg|
        froms << Regexp.new(arg)
      end
      
      o.on('-g TO', '--gsub-to', 'filter source code like s///g (to part)') do |arg|
        tos << arg
      end
      
      o.on('-c', '--case-sensitive', "make module name case sensitive (default: #{dep.case_sensitive})") do |a|
        dep.case_sensitive = a
      end
      
      o.on('-l', '--cluster', TrueClass, "clustering by directory structure (default: #{dep.cluster})") do |a|
        dep.cluster = a
      end
      
      o.parse!(argv)
      
      if froms.size != tos.size
        warn o.help
        abort "specify filter in form of: -s foo -g bar"
      end
      
      if argv.empty?
        abort o.help
      end
    end
    
    dep.source_code_filters = froms.zip(tos)
  
    dep.run(argv)
  end
  
  attr_accessor :ignore_file_matcher
  attr_accessor :source_code_filters
  attr_accessor :case_sensitive
  attr_accessor :cluster

  def initialize
    @io = STDOUT
    @ignore_file_matcher = nil
    @source_code_filters = []
    @case_sensitive = false
    @cluster = false
  end

  def run(globs)
    graph = scan(@source_code_filters, @case_sensitive, list(globs, @ignore_file_matcher))
    
    if @cluster && (clusters = calc_cluster(graph)).size >= 2
      print_cluster(graph, clusters)
    else
      print_flat(graph)
    end
  end
  
  private
  
  def list(globs, ignore)
    globs.map {|g| Dir[g].reject {|x| ignore === x } }.flatten
  end

  def scan(gsub, case_sensitive, sources)
    labels = sources.map {|x| calc_label x }
    nodenames = sources.map {|x| calc_nodename x }
    
    patterns = labels.map {|n| Regexp.escape(n).gsub('_', '_?') }.sort_by {|n| -n.size }
    pattern = Regexp.new("\\b(?:#{patterns.join('|')})", !case_sensitive)
    
    tree = {}
    sources.zip(nodenames, labels) do |filename, nodename, label|
      source = File.read(filename)
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
