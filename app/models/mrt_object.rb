class MrtObject
  extend MrtPaginator

  def initialize(id, doc=nil)
    @rsolr = RSolr.connect(:url => SOLR_SERVER)
    @id = id
    @doc = doc
  end

  def doc
    @doc ||= @rsolr.get('select', :params => {:q => "type:object and primaryId:#{@id}" })['response']['docs'][0]
  end

  def self.find_by_identifier(id)
    return MrtObjectSolr.new(id)
  end
  
  def self.get_collection(group_or_object)
    return nil
  end

  def self.find(*args)
    rsolr = RSolr.connect(:url => SOLR_SERVER)
    arg_hash = args.last
    sort = arg_hash[:sort] || RDF::DC['modified']
    order = arg_hash[:order] || "DESC"
    if arg_hash[:collection] then
      resp = rsolr.get('select', :params => { 
                         :q => "type:object AND memberOf:\"#{arg_hash[:collection]}\"",
                         :sort => "modified desc"
                       })
      return resp['response']['docs'].map { |d| MrtObject.new(d['primaryId'], d) }
    else
      return nil
    end
  end

  # XXX - integrate with find
  def self.count(*args)
    arg_hash = args.last
    q = if arg_hash[:collection] then
          Q.new("?o a object:Object ;
                    base:isInCollection <#{arg_hash[:collection]}> .",
                :select => "(count(?o) as ?count)")
        else
          raise Exception
        end
    return UriInfo.store().select(q)[0]['count'].value.to_i
  end

  def bytestream
    return doc['bytestream']
  end

  def bytestream_uri
    return URI.parse(self.bytestream)
  end
  
  def total_actual_size
    return doc['totalActualSize']
  end
  
  def modified
    return DateTime.parse(doc['modified'])
  end

  def created
    return DateTime.parse(doc['created'])
  end

  def size
    return doc['size']
  end

  def num_actual_files
    return doc['numActualFiles']
  end

  def versions
    return []
  end

  def who
    return doc['who']
  end

  def what
    return doc['what']
  end

  def when
    return doc['when']
  end

  def identifier
    return doc['primaryId']
  end

  def local_identifier
    return doc['localId']
  end

  def permalink
    return "#{N2T_URI}#{identifier.to_s}"
  end
  
  def files
    return []
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end
end
