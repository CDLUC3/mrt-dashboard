class MrtVersion < MrtSolr

  def solr_type
    return "version"
  end

  # is there a better way?
  def self.bulk_loader(q)
    MrtSolr.bulk_loader(MrtVersion, "type:version AND #{q}")
  end

  def identifier
    return doc['identifier']
  end

  def bytestream
    return doc['bytestream']
  end

  def bytestream_uri
    return self.bytestream.to_uri
  end
  
  def total_actual_size
    return doc['totalActualSize'].to_i
  end
  
  def created
    return DateTime.parse(doc['created'])
  end

  def size
    return doc['size'].to_i
  end

  def num_actual_files
    return doc['numActualFiles'].to_i
  end

  def files
    return @files ||= MrtFile.bulk_loader("inVersion:\"#{doc['storageUrl']}\"").
      sort_by{|f| f.identifier}
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end

  def in_object
    return @in_object ||= MrtObject.new(:q => "storageUrl:\"#{doc['inObject']}\"")
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
end
