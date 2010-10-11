# -*- mode: ruby -*-

xml.tag!('feed', :xmlns => "http://www.w3.org/2005/Atom") do 
  xml.tag!("link", "href" => "/objects/recent.atom",
           "rel" => "self", "type" => "application/atom+xml")
  if @objects.next_page then
    xml.tag!("link", "href" => "/objects/recent.atom?page=#{@objects.next_page}",
             "rel" => "next", "type" => "application/atom+xml")
  end
  if @objects.previous_page then
    xml.tag!("link", "href" => "/objects/recent.atom?start=#{@objects.previous_page}",
             "rel" => "previous", "type" => "application/atom+xml")
  end
  xml.tag!("link", "href" => "/objects/recent.atom?page=1",
           "rel" => "first", "type" => "application/atom+xml")
  xml.tag!("id", "urn:uuid:8dd71209-616a-4723-bfc1-b46572499932")
  xml.tag!("title", "Recent objects")
  if @objects[0] then
    xml.tag!("updated", w3cdtf(@objects[0].versions.last.created))
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
      xml.tag!("id", obj.is_stored_object_for.to_s)
      xml.tag!("title", obj.what)
      xml.tag!("author") do
        xml.tag!("name", obj.who)
      end
    end
  end
end
