class MrtFile < UriInfo
  Q = Mrt::Sparql::Q

  # Creates a MrtFile from a UriInfo object.
  def self.from_uri_info(uri_info)
    retval = MrtFile.new(uri_info.to_uri)
    retval.info = uri_info.info
    return retval
  end

  def self.bulk_loader(uris)
    results = UriInfo.bulk_loader(uris)
    return results.map {|uri_info| MrtFile.from_uri_info(uri_info) }
  end

  def identifier
    # this works with current storage service and saves a trip to
    # SPARQL when we just need the identifier
    return URI.decode(self.to_uri.path.match(/\/([^\/]+)$/)[1])
    #return self.first(RDF::DC['identifier']).value
  end

  def bytestream
    return self.first(Mrt::Model::Base['bytestream'])
  end

  def size
    return self.first(Mrt::Model::Base['size']).value.to_i
  end

  def created
    return DateTime.parse(self.first(RDF::DC['created']).value)
  end
  
  def media_type
    return self.first(Mrt::Model::File['mediaType']).value
  end

  def in_version
    return @version ||= MrtVersion.new(self.first(Mrt::Model::File['inVersion']))
  end
  
  def message_digest
    return self.first(Mrt::Model::File['messageDigest'])
  end
end
