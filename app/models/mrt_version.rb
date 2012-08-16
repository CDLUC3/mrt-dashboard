class MrtVersion < MrtSolr

  def solr_type
    return "version"
  end

  # is there a better way?
  def self.bulk_loader(p1)
    p2 = p1.clone
    p2[:q] = "type:version AND #{p1[:q]}"
    MrtSolr.bulk_loader(MrtVersion, p2)
  end

  def identifier
    return doc['versionNumber'].to_s
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
    return @files ||= MrtFile.bulk_loader(:q=>"inVersion:\"#{doc['storageUrl']}\"").
      sort_by{|f| f.identifier.downcase }
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }.
      sort_by {|x| File.basename(x.identifier.downcase) }     
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
