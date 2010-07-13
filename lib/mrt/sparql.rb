module Mrt
  module Sparql
    class Q
      attr_accessor :limit

      INITIALIZE_DEFARGS = { 
        :select => "*",
        :ns     => {
          :dc   => RDF::DC,
          :mrt  => RDF::Vocabulary.new("http://cdlib.org/mrt/"),
          :rdf  => RDF,
          :rdfs => RDF::RDFS,
          :xsd  => RDF::XSD
        }
      }

      def initialize(query, args={})
        @query = query
        @args = INITIALIZE_DEFARGS.merge(args)
      end
      
      def to_s()
        namespace_str = @args[:ns].keys.map do |key|
          "PREFIX #{key}: <#{@args[:ns][key].to_uri.to_s}>"
        end.join("\n")
        limit_str = if !@args[:limit].nil? then "LIMIT #{@args[:limit]}" else "" end
        order_by_str = if !@args[:order_by].nil? then "ORDER BY #{@args[:order_by]}" else "" end
        return "#{namespace_str} SELECT #{@args[:select]} WHERE { #{@query} } #{order_by_str} #{limit_str}"
      end
    end
    
    class Store
      def initialize(endpoint, options = nil)
        raise "4Store SPARQL end-point URI must end by '/sparql/'" if endpoint.split("/sparql/").size != 1
        @endpoint = URI.parse(endpoint)
        @proxy = URI.parse(ENV['HTTP_PROXY']) if ENV['HTTP_PROXY']
        @certificate = options["certificate"] if options
        @key = options["key"] if options
        @softlimit = options["soft-limit"] if options
      end
      
      def select(query)
        http.start do |h|
          request = Net::HTTP::Post.new(@endpoint.path)
          request.set_form_data({ 'query' => query.to_s, 'soft-limit' => @softlimit });
          request['Accept'] = 'application/json'
          response = h.request(request)
          parse_json_results(response.body)
        end
      end

      private
      def http
        if @proxy
          h = Net::HTTP::Proxy(@proxy.host, @proxy.port).new(@endpoint.host, @endpoint.port)
        else
          h = Net::HTTP.new(@endpoint.host, @endpoint.port)
        end
        if @certificate && @key
          require 'net/https'
          h.use_ssl = true
          h.cert = OpenSSL::X509::Certificate.new( File.read(@certificate) )
          h.key = OpenSSL::PKey::RSA.new( File.read(@key) )
          h.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        h
      end
      
      # Parse JSON results into a more usable format.
      def parse_json_results(raw)
        json =  JSON.parse(raw)
        json['results']['bindings'].map do |row|
          new_row = {}
          row.keys.each do |key|
            binding = row[key]
            new_row[key] = case binding['type']
                           when 'uri'
                             UriInfo.new(binding['value'])
                           when 'literal'
                             lang = if binding.has_key?('xml:lang') then binding['xml:lang'].intern else nil end
                             RDF::Literal.new(binding['value'], :language=>lang)
                           when 'typed-literal'
                             RDF::Literal.new(binding['value'], :type=>UriInfo.new(binding['type']))
                           when 'bnode'
                             RDF::Node.new(binding['value'])
                           end
          end
          new_row
        end
      end
    end
  end
end
