
class SourceCache
  def initialize(sequel)
    @sources = {}
    @sequel = sequel
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
    if record = @sequel[:source].select(:source).where(:sha1 => sha1).first
      @sources[path] = record[:source]
    else
      @sources[path] = lambda do
        src = promise.call
        @sequel[:source].insert(:source => src, :sha1 => sha1)
        @sources[path] = src
        src
      end
    end
  end
end
