class MrtFile < MrtSolr
  def solr_type
    return "file"
  end
  
  # is there a better way?
  def self.bulk_loader(p1)
    p2 = p1.clone
    p2[:q] = "type:file AND #{p2[:q]}"
    MrtSolr.bulk_loader(MrtFile, p2)
  end

  def identifier
    return doc['relativeId']
  end

  def bytestream
    return doc['bytestream']
  end

  def bytestream_uri
    return URI.parse(doc['bytestream'])
  end

  def size
    return doc['size'].to_i
  end

  def created
    return DateTime.parse(doc['created'])
  end
  
  def media_type
    return doc['mediaType']
  end

  def in_version
    return @version ||= MrtVersion.bulk_loader("storageUrl:\"#{doc['inVersion']}\"")[0]
  end
  
  def message_digest
    return doc['messageDigest']
  end
end
