class UriInfo < RDF::URI
  @store = Mrt::Sparql::Store.new("http://localhost:8080/sparql/") if @store.nil?
  class << self
    attr_accessor :store
  end
  
  def initialize(*args)
    super(*args)
    @info = nil
  end

  def keys
    cache_info if @info.nil?
    return @info.keys
  end

  def has_key?(key)
    cache_info if @info.nil?
    return @info.has_key?(key)
  end

  def [](key)
    cache_info if @info.nil?
    return @info[key]
  end

  def first(key, default=nil)
    cache_info if @info.nil?
    return (@info[key][0] || default)
  end

  def cache_info
    q = Mrt::Sparql::Q.new("<#{self.to_s}> ?p ?o .")
    res = UriInfo.store.select(q)
    @info = Hash.new
    res.each do |row|
      p = row['p']
      p = UriInfo.new(p) if p.instance_of? RDF::URI 
      o = row['o']
      o = UriInfo.new(o) if o.instance_of? RDF::URI 
      @info[p] ||= Array.new
      @info[p].push(o)
    end
  end
end
