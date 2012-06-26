# -*- mode: ruby -*-

xml.tag!('feed', :xmlns => "http://www.w3.org/2005/Atom") do 
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.current_page}",
           "rel"  => "self", 
           "type" => "application/atom+xml")
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection_ark}&page=1",
           "rel"  => "first", 
           "type" => "application/atom+xml")
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.total_pages}",
           "rel"  => "last",
           "type" => "application/atom+xml")
  if @objects.next_page
    xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.next_page}",
             "rel"  => "next", 
             "type" => "application/atom+xml")
  end
  if @objects.previous_page
    xml.tag!("link", 
             "href" => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.previous_page}",
             "rel"  => "previous", 
             "type" => "application/atom+xml")
  end
  xml.tag!("id", "urn:uuid:8dd71209-616a-4723-bfc1-b46572499932")
  xml.tag!("title", "Recent objects")
  if @objects[0] then
    xml.tag!("updated", w3cdtf(@objects[0].modified))
  else
    xml.tag!("updated", w3cdtf(Time.now))
  end
  xml.tag!("author") do
    xml.tag!("name", "California Digital Library")
    xml.tag!("email", "uc3@ucop.edu")
  end
  xml.tag!("generator", "UC3 Dashboard", "version" => "0", "uri" => "http://www.cdlib.org/")
  @objects.each do |obj|
    xml.tag!("entry") do
      ark = obj.is_stored_object_for.to_s
      xml.tag!("id", ark)
      xml.tag!("link", 
               "rel"  => "alternate",
               "type" => "application/zip",
               "href" => url_for(:controller => 'object', 
                                 :action     => 'download',
                                 :group      => @collection_ark,
                                 :object     => clean_id(ark)))

      if (!obj.local_identifier.nil?) then
        local_id = obj.local_identifier.value
        if (local_id.blank? && local_id.match(/^http/)) then
          xml.tag!("link",
                   "rel"  => "alternate",
                   "href" => local_id)
        end
      end
      xml.tag!("title", obj.what)
      xml.tag!("author") do
        xml.tag!("name", obj.who)
      end
      xml.tag!("updated", obj.modified)
      if (!obj.created.blank?) then
        xml.tag!("published", obj.created)
      end
      obj.files.each do |file|
        xml.tag!("link", 
                 "href" => url_for(:controller => 'file', 
                                   :action     => 'display',
                                   :object     => clean_id(ark),
                                   :version    => obj.versions.last.identifier,
                                   :file       => file.identifier),
                 "rel"  => "http://purl.org/dc/terms/hasPart")
      end
    end
  end
end
