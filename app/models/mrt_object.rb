class MrtObject < MrtSolr
  extend MrtPaginator

  def solr_type
    return "object"
  end

  # is there a better way?
  def self.bulk_loader(p1)
    p2 = p1.clone
    p2[:q] = "type:object AND #{p1[:q]}"
    MrtSolr.bulk_loader(MrtObject, p2)
  end

  def self.find_by_query(q)
    self.bulk_loader(:q=>q)[0]
  end
  
  def self.find_by_identifier(id)
    return MrtObject.new(:q => "primaryId:\"#{id}\"")
  end
  
  def self.find(*args)
    rsolr = RSolr.connect(:url => SOLR_SERVER)
    arg_hash = args.last
    sort = arg_hash[:sort] || "modified"
    order = arg_hash[:order] || "desc"
    if arg_hash[:collection] then
      return self.bulk_loader(:q => "memberOf:\"#{arg_hash[:collection]}\"", 
                              :sort => "#{sort} #{order}",
                              :start => arg_hash[:offset],
                              :rows => arg_hash[:limit])
    else
      return nil
    end
  end

  def self.count(*args)
    arg_hash = args.last
    if arg_hash[:collection] then
      MrtSolr.solr_count("type:object AND memberOf:\"#{arg_hash[:collection]}\"")
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
    return MrtVersion.bulk_loader(:q=>"inObject:\"#{doc['storageUrl']}\"")
  end

  def current_version
    return self.versions[-1]
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
    return self.current_version.files
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end

  def member_of
    return doc["memberOf"]
  end
end
