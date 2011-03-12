class MrtFile < UriInfo
  Q = Mrt::Sparql::Q

  def identifier
    # this works with current storage service and saves a trip to
    # SPARQL when we just need the identifier
    return URI.decode(self.to_uri.path.match(/\/([^\/]+)$/)[1])
    #return self.first(RDF::DC['identifier']).value
  end

  def bytestream
    return self.first(Mrt::Base['bytestream'])
  end

  def size
    return self.first(Mrt::Base['size']).value.to_i
  end

  def created
    return DateTime.parse(self.first(RDF::DC['created']).value)
  end
  
  def media_type
    return self.first(Mrt::File['mediaType']).value
  end

  def in_version
    return @version ||= MrtVersion.new(self.first(Mrt::File['inVersion']))
  end
  
  def message_digest
    return self.first(Mrt::File['messageDigest'])
  end
end
