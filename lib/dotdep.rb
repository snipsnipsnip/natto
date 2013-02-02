@ruby -x "%~f0" %* & exit /b
#!/usr/bin/ruby -Ku
require 'optparse'
require 'set'

class Dep
  attr_accessor :ignore_file_matcher
  attr_accessor :source_code_filters
  attr_accessor :case_sensitive
  attr_accessor :cluster

  def initialize(sources, out)
    @out = out
    @ignore_file_matcher = nil
    @source_code_filters = []
    @case_sensitive = false
    @cluster = false
    @sources = sources
  end

  def run(globs)
    graph = scan(@source_code_filters, @case_sensitive, list(globs, @ignore_file_matcher))
    print_flat(graph)
  end
  
  private
  
  def list(globs, ignore)
    globs.reject {|x| ignore === x }
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
  
  Node = Struct.new(:label, :files, :links)
  
  def make_node(label, filename)
    Node.new(label, [], Set.new)
  end
  
  def calc_label(filepath)
    File.basename(filepath, '.*')
  end
  
  def calc_nodename(filepath)
    calc_label(filepath).downcase.gsub('_', '')
  end
  

  def print_flat(dep)
    dep.each do |node_name, node|
      print_node(dep, node_name, node, indent)
    end
    
    dep.each do |s, node|
      node.links.each do |d|
        print_link s, d, indent
      end
    end
  end
  
  def print_link(from, to, indent=nil)
    @out.link(from, to) if from != to
  end
  
  def print_node(graph, node_name, node, indent=nil)
    fan_in = graph.count {|n,d| d.links.include?(node_name) }
    fan_out = node.links.size
    @out.node(node_name, node.label, node.files, fan_in, fan_out)
  end
end

Dep.main if $0 == __FILE__