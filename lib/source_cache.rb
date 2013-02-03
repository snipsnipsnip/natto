
class SourceCache
  def initialize(sequel)
    @sources = {}
    @sequel = sequel
    
    sequel.create_table?(:blob_cache) do
      String :sha1, :primary_key => true, :null => false
      String :content, :null => false
      String :path, :null => false
    end
  end
  
  def [](path)
    src = @sources[path]
    if src.respond_to?(:call)
      src.call
    else
      src
    end
  end
  
  def add(sha1, path, promise)
    if record = @sequel[:blob_cache].select(:content).where(:sha1 => sha1).first
      @sources[path] = record[:content]
    else
      @sources[path] = lambda do
        src = promise.call
        @sequel[:blob_cache].insert(:content => src, :sha1 => sha1, :path => path)
        @sources[path] = src
        src
      end
    end
  end
end
