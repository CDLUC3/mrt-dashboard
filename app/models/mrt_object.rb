class MrtObject < MrtSolr
  extend MrtPaginator

  def solr_type
    return "object"
  end

  def self.bulk_loader(q)
    MrtSolr.bulk_loader(MrtObject, "type:#{solr_type} AND #{q}")
  end

  def self.find_by_identifier(id)
    return MrtObject.new(:q => "primaryId:\"#{id}\"")
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
      return resp['response']['docs'].map { |d| MrtObject.new(d) }
    else
      return nil
    end
  end

  def self.count(*args)
    rsolr = RSolr.connect(:url => SOLR_SERVER)
    arg_hash = args.last
    if arg_hash[:collection] then
      return rsolr.get('select', :params => {
                         :q => "type:object AND memberOf:\"#{arg_hash[:collection]}\"",
                         :fl => "none" })['response']['numFound']
    else
      raise Exception
    end
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
    return MrtVersion.bulk_loader("inObject:\"#{doc['storageUrl']}\"")
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

  def primary_id
    return doc['primaryId']
  end

  def identifier
    return self.primary_id
  end

  def local_id
    return doc['localId']
  end

  # deprecated
  def local_identifier
    return doc['localId']
  end

  def permalink
    return "#{N2T_URI}#{identifier.to_s}"
  end
  
  def files
    return self.versions[-1].files
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end
end
