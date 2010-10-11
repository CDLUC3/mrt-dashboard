class UriInfo < RDF::URI
  @store = Mrt::Sparql::Store.new(SPARQL_ENDPOINT) if @store.nil?
  class << self
    attr_accessor :store
  end

  def self.maybe_make(o)
    if o.instance_of? RDF::URI then
      return UriInfo.new(o)
    else
      return o
    end
  end

  def self.bulk_loader(uris)
    uris_str = uris.map{|uri| "<#{uri}>"}.join(", ")
    q = Mrt::Sparql::Q.new(nil, :describe=>uris_str)
    return self.query_bulk_loader(q)
  end

  def self.query_bulk_loader(query)
    graph = UriInfo.store.select(query)
    uris = Hash.new
    return graph.subjects.map do |uri|
      u = self.new(uri)
      u.cache_from_graph(graph)
    end
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
    fill_cache if @info.nil?
    return @info.keys
  end

  def has_key?(key)
    fill_cache if @info.nil?
    return @info.has_key?(key)
  end

  def [](key)
    fill_cache if @info.nil?
    return @info[key]
  end

  def first(key, default=nil)
    fill_cache if @info.nil?
    d = @info[key]
    if d.nil? then return default
    else return (d[0] || default) end
  end

  def fill_cache
    q = Mrt::Sparql::Q.new("<#{self.to_s}> ?p ?o")
    res = UriInfo.store.select(q)
    cache_from(res.map { |row|
                 [self, 
                  UriInfo.maybe_make(row['p']),
                  UriInfo.maybe_make(row['o'])]})
  end
  
  def cache_from(data)
    @info = Hash.new
    known_uris = Hash.new
    data.each do |row|
      (s,p,o) = *row
      known_uris[s] ||= s if s.instance_of? UriInfo
      known_uris[p] ||= p if p.instance_of? UriInfo
      known_uris[o] ||= o if o.instance_of? UriInfo
      @info[p] ||= Array.new
      @info[p].push(o)
    end
    return self
  end

  def cache_from_graph(graph)
    @info = Hash.new
    graph.each_statement do |stmt|
      if (stmt.subject == self) then
        @info[stmt.predicate] ||= []
        @info[stmt.predicate].push(stmt.object)
      end
    end
    return self
  end
end
