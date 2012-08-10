class MrtFile < MrtSolr
  def solr_type
    return "file"
  end
  
  # is there a better way?
  def self.bulk_loader(q)
    MrtSolr.bulk_loader(MrtFile, "type:file AND #{q}")
  end

  def identifier
    return doc['relativeId']
  end

  def bytestream
    return doc['bytestream']
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
    return @version ||= MrtVersion.from_query("storageUrl:\"#{doc['inVersion']}\"")
  end
  
  def message_digest
    return doc['messageDigest']
  end
end
