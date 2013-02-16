# coding: utf-8

require 'fileutils'

class Repo
  def initialize(git_binary, reposdir)
    @git_binary = git_binary
    @reposdir = reposdir
  end
  
  # yields each blob: [sha1, path, () -> content]
  def each_blob(reponame)
    unless reponame =~ /[a-z\d_-]+\/[a-z\d_-]+/i
      raise ArgumentError, "reponame seems invalid"
    end
    
    repourl = "git://github.com/#{reponame}"
    repodir = File.join(@reposdir, reponame)
    if Dir.exist?(repodir)
      git %W[--work-tree #{repodir} --git-dir #{File.join(repodir, '.git')} fetch]
    else
      FileUtils::Verbose.mkdir_p repodir
      git %W[clone #{repourl} #{repodir}]
    end
    
    git_with_result(%W[ls-tree -r --full-name HEAD]) do |line|
      record = line.split
      record.size == 4 or raise "#{cmd.inspect} failed"
      mod, type, sha, path = record
      yield sha, path, lambda { File.read(File.join(repodir, path)) }
    end
  end
  
  private
  def git_with_result(args, &blk)
    result = `#{@git_binary} #{args.join(' ')}`
    $? == 0 or raise "#{cmd.inspect} failed"
    result.each_line(&blk)
  end
  
  def git(args)
    cmd = [@git_binary, *args]
    warn cmd.inspect
    system *cmd
    $? == 0 or raise "#{cmd.inspect} failed"
  end
end
