require 'rdf/raptor'

module Mrt
  module Sparql
    class Q
      attr_accessor :limit
      ::RDF::URI::CACHE_SIZE = 0

      INITIALIZE_DEFARGS = { 
        :select => "*",
        :ns     => {
          :base    => RDF::Vocabulary.new("http://uc3.cdlib.org/ontology/store/base#"),
          :dc      => RDF::DC,
          :file    => RDF::Vocabulary.new("http://uc3.cdlib.org/ontology/store/file#"),
          :mulgara => RDF::Vocabulary.new("http://mulgara.org/mulgara#"),
          :object  => RDF::Vocabulary.new("http://uc3.cdlib.org/ontology/store/object#"),
          :ore     => RDF::Vocabulary.new("http://www.openarchives.org/ore/terms/"),
          :rdf     => RDF,
          :rdfs    => RDF::RDFS,
          :store   => RDF::Vocabulary.new("http://uc3.cdlib.org/ontology/store/store#"),
          :version => RDF::Vocabulary.new("http://uc3.cdlib.org/ontology/store/version#"),
          :xsd     => RDF::XSD
        }
      }

      def initialize(query, args={})
        @query = query
        @args = INITIALIZE_DEFARGS.merge(args)
      end
      
      def to_s()
        namespace_str = @args[:ns].keys.map do |key|
          "PREFIX #{key}: <#{@args[:ns][key].to_uri.to_s}>"
        end.join(" ")
        limit_str = if !@args[:limit].nil? then "LIMIT #{@args[:limit]}" else "" end
        offset_str = if !@args[:offset].nil? then "OFFSET #{@args[:offset]}" else "" end
        order_by_str = if !@args[:order_by].nil? then "ORDER BY #{@args[:order_by]}" else "" end
        where_str = if !@query.blank? then "{ #{@query} }" else "{}" end
        select_or_desc_str = if !@args[:describe].blank? then
                               "DESCRIBE #{@args[:describe]}"
                             else
                               "SELECT #{@args[:select]}"
                             end
        from_str = "" # "FROM <http://merritt.cdlib.org/>"
        return "#{namespace_str} #{select_or_desc_str} #{from_str} WHERE #{where_str} #{order_by_str} #{limit_str} #{offset_str}"
      end
    end
    
    class Store
      def initialize(endpoint, options = nil)
        raise "4Store SPARQL end-point URI must end by '/sparql/'" if endpoint.split("/sparql/").size != 1
        @endpoint = URI.parse(endpoint)
        @proxy = URI.parse(ENV['HTTP_PROXY']) if ENV['HTTP_PROXY']
        @certificate = options["certificate"] if options
        @key = options["key"] if options
        @softlimit = (options["soft-limit"] if options) || 1000000
      end
      
      def select(query)
        http.start do |h|
          request = Net::HTTP::Post.new(@endpoint.path)
          request.set_form_data({ 'query' => query.to_s, 'soft-limit' => @softlimit });
          #4store accept header not working right
          if query.to_s.match(/DESCRIBE/) then
            request['Accept'] = 'application/rdf+xml'
          else
            request['Accept'] = 'application/sparql-results+json'
          end
          response = h.request(request)
          case response['Content-Type'].sub(/;.*$/, "")
          when "application/rdf+xml"
            parse_rdf_xml_results(response.body)
          when "application/sparql-results+json"
            parse_json_results(response.body)
          when "application/sparql-results+xml"
            parse_xml_results(response.body)
          end
        end
      end

      private
      def http
        if @proxy
          h = Net::HTTP::Proxy(@proxy.host, @proxy.port).new(@endpoint.host, @endpoint.port)
        else
          h = Net::HTTP.new(@endpoint.host, @endpoint.port)
        end
        h.read_timeout=600
        if @certificate && @key
          require 'net/https'
          h.use_ssl = true
          h.cert = OpenSSL::X509::Certificate.new( File.read(@certificate) )
          h.key = OpenSSL::PKey::RSA.new( File.read(@key) )
          h.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        h
      end
      
      def parse_xml_results(raw)
        ns = { "sparql" => "http://www.w3.org/2005/sparql-results#" }
        xml_doc  = Nokogiri::XML(raw)
        return xml_doc.xpath("/sparql:sparql/sparql:results/sparql:result", ns).map do |result|
          new_row = {}
          result.xpath("sparql:binding", ns).each do |binding|
            val = binding.xpath("sparql:literal|sparql:uri", ns)[0]
            new_row[binding['name']] = case val.name
                                       when 'uri'
                                         UriInfo.new(val.xpath("text()"))
                                       when 'literal'
                                         lang = nil
                                         #lang = if binding.has_key?('xml:lang') then binding['xml:lang'].intern else nil end
                                         datatype = if val['datatype'] then UriInfo.new(val['datatype']) else nil end
                                         RDF::Literal.new(val.xpath("text()"),
                                                          :type=> datatype,
                                                          :language=>lang)
                                       when 'bnode'
                                         # TODO!
                                       end
          end
          new_row
        end
      end

      def parse_rdf_xml_results(raw)
        retval = RDF::Graph.new
        RDF::Reader.for(:rdfxml).new(raw) do |reader|
          reader.each do |stmt|
            retval.insert(stmt)
          end
        end
        return retval
      end

      # Parse JSON results into a more usable format.
      def parse_json_results(raw)
        json = JSON.parse(raw)
        json['results']['bindings'].map do |row|
          new_row = {}
          row.keys.each do |key|
            binding = row[key]
            new_row[key] = case binding['type']
                           when 'uri'
                             UriInfo.new(binding['value'])
                           when 'literal'
                             lang = if binding.has_key?('xml:lang') then binding['xml:lang'].intern else nil end
                             datatype = if binding.has_key?('datatype') then UriInfo.new(binding['datatype']) else nil end
                             RDF::Literal.new(binding['value'], :language=>lang, :datatype=>datatype)
                           when 'typed-literal'
                             RDF::Literal.new(binding['value'], :type=>UriInfo.new(binding['type']))
                           when 'bnode'
                             # a hack that works with 4store
                             UriInfo.new("bnode:#{binding['value']}")
                           end
          end
          new_row
        end
      end
    end
  end
end
