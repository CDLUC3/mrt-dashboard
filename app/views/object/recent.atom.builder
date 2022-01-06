# -*- mode: ruby -*- 

xml.tag!('feed', :xmlns => 'http://www.w3.org/2005/Atom',
                 'xmlns:dct' => 'http://purl.org/dc/terms/',
                 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/') do
  xml.tag!('link',
           'href' => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.current_page}&per_page=#{@objects.per_page}",
           'rel' => 'self',
           'type' => 'application/atom+xml')
  xml.tag!('link',
           'href' => "/object/recent.atom?collection=#{@collection_ark}&page=1&per_page=#{@objects.per_page}",
           'rel' => 'first',
           'type' => 'application/atom+xml')
  xml.tag!('link',
           'href' => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.total_pages}&per_page=#{@objects.per_page}",
           'rel' => 'last',
           'type' => 'application/atom+xml')
  if @objects.next_page
    xml.tag!('link',
             'href' => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.next_page}&per_page=#{@objects.per_page}",
             'rel' => 'next',
             'type' => 'application/atom+xml')
  end
  if @objects.previous_page
    xml.tag!('link',
             'href' => "/object/recent.atom?collection=#{@collection_ark}&page=#{@objects.previous_page}&per_page=#{@objects.per_page}",
             'rel' => 'previous',
             'type' => 'application/atom+xml')
  end
  xml.tag!('id', 'urn:uuid:8dd71209-616a-4723-bfc1-b46572499932')
  xml.tag!('title', 'Recent objects')
  if @objects[0]
    xml.tag!('updated', @objects[0].modified.to_formatted_s(:w3cdtf))
  else
    xml.tag!('updated', Time.now.to_formatted_s(:w3cdtf))
  end
  xml.tag!('author') do
    xml.tag!('name', 'California Digital Library')
    xml.tag!('email', 'uc3@ucop.edu')
  end
  xml.tag!('generator', 'UC3 Dashboard', 'version' => '0', 'uri' => 'http://www.cdlib.org/')
  @objects.each do |obj|
    xml.tag!('entry') do
      xml.tag!('id', obj.permalink)
      xml.tag!('link',
               'rel' => 'alternate',
               'type' => 'application/zip',
               'href' => url_for(controller: 'object',
                                 action: 'presign',
                                 object: obj))
      xml.tag!('dct:extent', obj.size.to_s)
      obj.all_local_ids.each do |local_id|
        
        xml.tag!('dc:identifier', local_id)

        next unless local_id && local_id.match(/^http/)

        xml.tag!('link',
                 'rel' => 'alternate',
                 'href' => local_id)
      end
      xml.tag!('title', dc_nice(obj.current_version.dk_what))
      obj.current_version.dk_who.each do |name|
        xml.tag!('author') do
          xml.tag!('name', name)
        end
      end
      xml.tag!('updated', obj.modified.to_formatted_s(:w3cdtf))
      xml.tag!('published', obj.created.to_formatted_s(:w3cdtf)) unless obj.created.blank?
      current_version = obj.current_version
      current_version.inv_files.each do |file|
        xml.tag!('link',
                 'href' => presigned_link_uri(obj, current_version, file),
                 'rel' => 'http://purl.org/dc/terms/hasPart',
                 'title' => file.pathname,
                 'length' => file.full_size,
                 'type' => file.mime_type,
                 'digest' => file.digest_value)
      end
    end
  end
end
