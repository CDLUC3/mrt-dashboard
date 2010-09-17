# -*- mode: ruby -*-

xml.tag!('feed', :xmlns => "http://www.w3.org/2005/Atom") do 
  xml.tag!("link", "href" => "/objects/recent.atom",
           "rel" => "self", "type" => "application/atom+xml")
  xml.tag!("link", "href" => "/objects/recent.atom?start=#{@next_start}",
           "rel" => "next", "type" => "application/atom+xml")
  xml.tag!("link", "href" => "/objects/recent.atom?start=#{@previous_start}",
           "rel" => "previous", "type" => "application/atom+xml")
  xml.tag!("link", "href" => "/objects/recent.atom",
           "rel" => "first", "type" => "application/atom+xml")
  xml.tag!("id", "urn:uuid:8dd71209-616a-4723-bfc1-b46572499932")
  xml.tag!("title", "Recent objects")
  if @recent_objects[0] then
    xml.tag!("updated", w3cdtf(@recent_objects[0].first(Mrt::Object['hasStoredObject']).first(RDF::DC.modified)))
  else
    xml.tag!("updated", w3cdtf(Time.now))
  end
  xml.tag!("author") do
    xml.tag!("name", "California Digital Library")
    xml.tag!("email", "who@ucop.edu")
  end
  xml.tag!("generator", "UC3 Dashboard", "version" => "0", "uri" => "http://www.cdlib.org/")
  @recent_objects.each do |obj|
    s_obj = obj.first(Mrt::Object['hasStoredObject'])
    xml.tag!("entry") do
      xml.tag!("id", (obj.to_s))
      xml.tag!("title", (obj.first(Mrt::Kernel.what).to_s))
      xml.tag!("author") do
        xml.tag!("name", (obj.first(Mrt::Kernel.who).to_s))
      end
      xml.tag!("updated", w3cdtf(s_obj.first(RDF::DC.modified)))
      xml.tag!("published", w3cdtf(s_obj.first(RDF::DC.created)))
      xml.tag!("link", "href" => "/show/#{clean_id(obj)}",
               "rel" => "alternate")
      currentVersion = s_obj.first(Mrt::Object['versionSeq']).to_list.last
      if currentVersion then
        currentVersion[Mrt::Version['hasFile']].each do |file|
          xml.tag!("link", 
                   "href" => "http://gales.cdlib.org:3000/show/view/#{file.to_s}",
                   "rel"  => "http://purl.org/dc/terms/hasPart")
        end
      end
    end
  end
end
