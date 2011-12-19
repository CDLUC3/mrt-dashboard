class UriInfo < RDF::URI
  @store = Mrt::Sparql::Store.new(SPARQL_ENDPOINT) if @store.nil?
  class << self
    attr_accessor :store
  end

  attr_accessor :info

  def self.maybe_make(o)
    if o.instance_of? RDF::URI then
      return UriInfo.new(o)
    else
      return o
    end
  end

  BULK_LOADER_MAX = 50

  def self.bulk_loader(uris)
    if (uris.size > BULK_LOADER_MAX) then
      return self.bulk_loader(uris[0..(BULK_LOADER_MAX-1)]) + self.bulk_loader(uris[BULK_LOADER_MAX..-1])
    else
      indexes = (0..(uris.size-1)).to_a
      q_str = ""
      indexes.each do |i|
        graph_uri = URI.decode(uris[i].to_uri.to_s)
        q_str += "{ OPTIONAL { <#{uris[i]}> ?p#{i} ?o#{i} . } }\n"
      end
      results = UriInfo.store.select(Mrt::Sparql::Q.new(q_str))
      
      retval = uris.map {|uri| self.new(uri)}
      results.each do |row|
        indexes.each do |i|
          if !row["p#{i}"].nil? then
            retval[i].cache_vals(row["p#{i}"], row["o#{i}"])
          end
        end
      end
      return retval
    end
  end

  def self.query_bulk_loader(query)
    results = UriInfo.store.select(query)
    known_uris = Hash.new
    subjects = Hash.new
    results.each do |row|
      (s,p,o) = *row
      known_uris[s] ||= s if s.instance_of? UriInfo
      subjects[s] ||= s
      known_uris[p] ||= p if p.instance_of? UriInfo
      known_uris[o] ||= o if o.instance_of? UriInfo
      known_uris[s].cache_vals(known_uris[p], known_uris[o])
    end
    return subjects.keys
  end

  def initialize(uri, graph_uri=nil, *rest)
    super(uri, *rest)
    @graph_uri = graph_uri
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
    return @info[key] || []
  end

  def first(key, default=nil)
    fill_cache if @info.nil?
    d = @info[key]
    if d.nil? then return default
    else return (d[0] || default) end
  end

  def first_value(key, default=nil)
    tmp = first(key, default)
    if tmp.nil? then
      return nil
    else
      return tmp.value
    end
  end

  def fill_cache
    q = if @graph
          Mrt::Sparql::Q.new("GRAPH <#{@graph}> { <#<#{self.to_s}> ?p ?o }")
        else 
          Mrt::Sparql::Q.new("<#{self.to_s}> ?p ?o")
        end
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

  def cache_vals(p, o)
    @info ||= Hash.new
    @info[p] ||= []
    @info[p].push(o)
  end
end
