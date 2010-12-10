class MrtObject < UriInfo
  extend MrtPaginator
  
  Q = Mrt::Sparql::Q

  # Creates a MrtObject from a UriInfo object.
  def self.from_uri_info(uri_info)
    retval = MrtObject.new(uri_info.to_uri)
    retval.info = uri_info.info
    return retval
  end

  def self.find_by_identifier(id)
    q = Q.new("?obj rdf:type object:Object .
               ?obj dc:identifier \"#{id}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?obj")
    return MrtObject.new(UriInfo.store().select(q)[0]['obj'])
  end

  def self.bulk_loader(uris)
    results = UriInfo.bulk_loader(uris)
    return results.map {|uri_info| MrtObject.from_uri_info(uri_info) }
  end
  
  def self.find(*args)
    arg_hash = args.last
    sort = arg_hash[:sort] || RDF::DC['modified']
    order = arg_hash[:order] || "DESC"
    q = if arg_hash[:collection] then
          Q.new("?o a object:Object ;
                    base:isInCollection <#{arg_hash[:collection]}> ;
                    <#{sort}> ?sort .",
                :select   => "?o",
                :order_by => "#{order}(?sort)",
                :offset   => arg_hash[:offset],
                :limit    => arg_hash[:limit])
        else
          raise Exception
        end
    return MrtObject.bulk_loader(UriInfo.store.select(q).map{|row|row['o']})
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
    return self.first(Mrt::Base['bytestream'])
  end
  
  def total_actual_size
    return self.first(Mrt::Object['totalActualSize']).value.to_i
  end
  
  def modified
    return DateTime.parse(self.first(RDF::DC['modified']).value)
  end

  def size
    return self.first(Mrt::Base['size']).value.to_i
  end

  def in_node
    return self.first(Mrt::Object['inNode'])
  end

  def num_actual_files
    return self.first(Mrt::Object['numActualFiles']).value.to_i
  end

  def versions
    # this works with current storage service and saves a trip to
    # SPARQL
    return @versions ||= self[RDF::DC["hasVersion"]].map{|uri| MrtVersion.new(uri)}.sort_by{|v| v.identifier}
    #return @versions ||= self.first(Mrt::Object['versionSeq']).to_list.map{|v| MrtVersion.new(v)}
  end

  def is_stored_object_for
    return self.first(Mrt::Object['isStoredObjectFor'])
  end

  def who
    return self[Mrt::Kernel['who']].map { |el| el.value.to_s }
  end

  def what
    return self[Mrt::Kernel['what']].map { |el| el.value.to_s }
  end

  def when
    return self[Mrt::Kernel['when']].map { |el| el.value.to_s }
  end

  def identifier
    return self.first(RDF::DC['identifier'])
  end

  def local_identifier
    return self.is_stored_object_for.first(Mrt::Object.localIdentifier)
  end

  def files
    return @files ||= self[Mrt::Version['hasFile']].map{|u| MrtFile.new(u)}.sort_by{|f| f.identifier}
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end
end
