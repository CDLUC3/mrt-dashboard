class UriInfo < RDF::URI
  @store = Mrt::Sparql::Store.new(SPARQL_ENDPOINT) if @store.nil?
  class << self
    attr_accessor :store
  end
  
  def initialize(*args)
    super(*args)
    @info = nil
  end

  def has_list?
    return self[RDF['type']].first == RDF['Seq'].to_uri
  end

  def to_list
    if self.has_list? then
      a = Array.new
      self.keys.each do |key|
        if (md = key.to_s.match(/_([0-9]+)$/)) then
          n = (md[1].to_i - 1)
          a[n] = self[key].first
          a[n] = UriInfo.new(a[n]) if a[n].instance_of? RDF::URI 
        end
      end
      return a
    end
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
    d = @info[key]
    if d.nil? then return default
    else return (d[0] || default) end
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
