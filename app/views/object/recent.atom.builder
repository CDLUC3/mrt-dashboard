# -*- mode: ruby -*-

xml.tag!('feed', :xmlns => "http://www.w3.org/2005/Atom") do 
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection}&page=#{@objects.current_page}",
           "rel"  => "self", 
           "type" => "application/atom+xml")
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection}&page=1",
           "rel"  => "first", 
           "type" => "application/atom+xml")
  xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection}&page=#{@objects.total_pages}",
           "rel"  => "last",
           "type" => "application/atom+xml")
  if @objects.next_page
    xml.tag!("link", 
           "href" => "/object/recent.atom?collection=#{@collection}&page=#{@objects.next_page}",
             "rel"  => "next", 
             "type" => "application/atom+xml")
  end
  if @objects.previous_page
    xml.tag!("link", 
             "href" => "/object/recent.atom?collection=#{@collection}&page=#{@objects.previous_page}",
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
                                 :group      => @collection,
                                 :object     => clean_id(ark)))
      xml.tag!("title", obj.what)
      xml.tag!("author") do
        xml.tag!("name", obj.who)
      end
      xml.tag!("updated", obj.modified)
      current_version = obj.versions.last
      if current_version then
        current_version.files.each do |file|
          xml.tag!("link", 
                   "href" => url_for(:controller => 'file', 
                                     :action     => 'display',
                                     :object     => clean_id(ark),
                                     :version    => current_version.identifier,
                                     :file       => file.identifier),
                   "rel"  => "http://purl.org/dc/terms/hasPart")
        end
      end
    end
  end
end
