class MrtObject < UriInfo
  Q = Mrt::Sparql::Q

  def self.find_by_identifier(id)
    q = Q.new("?obj rdf:type object:Object .
               ?obj dc:identifier \"#{id}\"^^<http://www.w3.org/2001/XMLSchema#string>",
      :select => "?obj")
    return MrtObject.new(UriInfo.store().select(q)[0]['obj'])
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
    return @versions ||= self.first(Mrt::Object['versionSeq']).to_list.map{|v| MrtVersion.new(v)}
  end

  def is_stored_object_for
    return self.first(Mrt::Object['isStoredObjectFor'])
  end

  def identifier
    return self.first(RDF::DC['identifier'])
  end
end
