require 'rake/clean'
require 'rake/testtask'

@tilts = {}

def tilt_rule(to, from, options={})
  @tilts[from] = to

  rule to => from do |task|
    require 'tilt'

    puts "#{task.source} -> #{task.name}" if verbose
    
    template = Tilt.new(task.source)
    template.options.merge(options)
    
    result = template.render
    open(task.name, 'wb') {|f| f << result }
  end
end

def desugared_files
  @desugared_files ||= FileList.new do |list|
    @tilts.each {|from, to| list.add FileList["**/*#{from}"].ext(to) }
  end
end


tilt_rule '.css', '.sass'
tilt_rule '.js', '.coffee'

CLEAN.add desugared_files

desc "desugar all files (#{@tilts.map {|k,v| "#{k}=>#{v}" }.join(',')})"
task 'desugar' => desugared_files

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = true
end

task 'default' => %w[desugar]
