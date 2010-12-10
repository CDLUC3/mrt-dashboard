class MrtVersion < UriInfo
  Q = Mrt::Sparql::Q

  def identifier
    # this works with current storage service and saves a trip to
    # SPARQL when we just need the identifier
    return self.to_uri.path.match(/\/([0-9]+)$/)[1]
#    return self.first(RDF::DC['identifier']).value
  end

  def bytestream
    return self.first(Mrt::Base['bytestream'])
  end
  
  def total_actual_size
    return self.first(Mrt::Base['totalActualSize']).value.to_i
  end
  
  def created
    return DateTime.parse(self.first(RDF::DC['created']).value)
  end

  def size
    return self.first(Mrt::Base['size']).value.to_i
  end

  def num_actual_files
    return self.first(Mrt::Object['numActualFiles']).value.to_i
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

  def in_object
    return @in_object ||= MrtObject.new(self.first(Mrt::Version['inObject']))
  end

  def who
    return self[Mrt::Kernel['who']].map{ |w| w.value.to_s }
  end

  def what
    return self[Mrt::Kernel['what']].map{ |w| w.value.to_s }
  end

  def when
    return self[Mrt::Kernel['when']].map{ |w| w.value.to_s }
  end
end
