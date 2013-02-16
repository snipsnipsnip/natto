
class SourceCache
  def initialize(sequel)
    @sources = {}
    @paths = {}
    @sequel = sequel
    
    sequel.create_table?(:blob_cache) do
      String :sha1, :primary_key => true, :null => false
      text :content, :null => false
    end
  end
  
  def [](sha1)
    src = @sources.fetch(sha1)
    if src.respond_to?(:call)
      src.call
    else
      src
    end
  end
  
  def add(sha1, path, promise)
    @paths[sha1] = path
    if record = @sequel[:blob_cache].select(:content).where(:sha1 => sha1).first
      @sources[sha1] = record[:content]
    else
      @sources[sha1] = lambda do
        src = promise.call
        @sequel[:blob_cache].insert(:content => src, :sha1 => sha1)
        @sources[sha1] = src
        src
      end
    end
  end
  
  def path_of(sha1)
    @paths.fetch(sha1)
  end
end
