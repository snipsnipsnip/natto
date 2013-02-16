# coding: utf-8

require 'octokit'

# Github APIを使ってリポジトリ中のblobを取得する。
class OctoWalker
  def initialize(kit_or_options)
    @kit = kit_or_options.respond_to?(:repo) ? kit_or_options : Octokit::Client.new(kit_or_options)
  end
  
  # yields each blob: [sha1, path, () -> content]
  def each_blob(reponame)
    repoinfo = @kit.repo(reponame)
    commit_info = @kit.list_commits(reponame, repoinfo.default_branch, :per_page => 1)[0]
    commit = @kit.commit(reponame, commit_info.sha)
    tree = @kit.tree(reponame, commit.commit.tree.sha, :recursive => 1)
    
    tree.tree.each do |object|
      if object.type == 'blob'
        content = lambda { @kit.blob(reponame, object.sha, :accept => 'application/vnd.github.raw') }
        yield object.sha, object.path, content
      end
    end
  end
end
