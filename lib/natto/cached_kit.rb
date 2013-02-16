
class CachedKit
  def initialize(sequel, octokit)
    @sequel = sequel
    @octokit = octokit
    
    sequel.create_table?(:tree_commit_cache) do
      String :sha1, :primary_key => true, :null => false
      text :content, :null => false
    end
  end
  
  def repo(reponame)
    @octokit.repo(reponame)
  end
  
  def commit(reponame, sha)
    @octokit.commit(reponame, sha)
  end
  
  def tree(reponame, sha, opt)
    @octokit.tree(reponame, sha, opt)
  end
  
  def list_commits(reponame, branch, opt)
    @octokit.list_commits(reponame, branch, opt)
  end
  
  def blob(reponame, sha, opt)
    @octokit.blob(reponame, sha, opt)
  end
end
