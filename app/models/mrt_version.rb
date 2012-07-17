class MrtVersion < UriInfo
  Q = Mrt::Sparql::Q

  def identifier
    # this works with current storage service and saves a trip to
    # SPARQL when we just need the identifier
    return self.to_uri.path.match(/\/([0-9]+)$/)[1]
#    return self.first(RDF::DC['identifier']).value
  end

  def bytestream
    return self.first(Mrt::Model::Base['bytestream'])
  end

  def bytestream_uri
    return self.bytestream.to_uri
  end
  
  def total_actual_size
    return self.first(Mrt::Model::Base['totalActualSize']).value.to_i
  end
  
  def created
    return DateTime.parse(self.first(RDF::DC['created']).value)
  end

  def size
    return self.first(Mrt::Model::Base['size']).value.to_i
  end

  def num_actual_files
    return self.first(Mrt::Model::Object['numActualFiles']).value.to_i
  end

  def files
    return @files ||= MrtFile.bulk_loader(self[Mrt::Model::Version['hasFile']]).
      sort_by{|f| f.identifier}
  end

  def system_files 
    return self.files.select {|f| f.identifier.match(/^system\//) }
  end

  def producer_files 
    return self.files.select {|f| f.identifier.match(/^producer\//) }
  end

  def in_object
    return @in_object ||= MrtObject.new(self.first(Mrt::Model::Version['inObject']))
  end

  def who
    return self[Mrt::Model::Kernel['who']].map{ |w| w.value.to_s }
  end

  def what
    return self[Mrt::Model::Kernel['what']].map{ |w| w.value.to_s }
  end

  def when
    return self[Mrt::Model::Kernel['when']].map{ |w| w.value.to_s }
  end
end
