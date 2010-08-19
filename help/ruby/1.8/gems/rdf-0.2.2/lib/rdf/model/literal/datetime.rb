module RDF; class Literal
  ##
  # A date/time literal.
  #
  # @see   http://www.w3.org/TR/xmlschema-2/#dateTime
  # @since 0.2.1
  class DateTime < Literal
    DATATYPE = XSD.dateTime
    GRAMMAR  = %r(\A-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(([\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze

    ##
    # @param  [DateTime] value
    # @option options [String] :lexical (nil)
    def initialize(value, options = {})
      @datatype = RDF::URI(options[:datatype] || DATATYPE)
      @string   = options[:lexical] if options.has_key?(:lexical)
      @string   = value if !defined?(@string) && value.is_a?(String)
      @object   = case
        when value.is_a?(::DateTime)         then value
        when value.respond_to?(:to_datetime) then value.to_datetime # Ruby 1.9+
        else ::DateTime.parse(value.to_s)
      end
    end

    ##
    # Converts the literal into its canonical lexical representation.
    #
    # @return [Literal]
    # @see    http://www.w3.org/TR/xmlschema-2/#dateTime
    def canonicalize
      @string = @object.strftime('%Y-%m-%dT%H:%M:%S%Z').sub(/\+00:00|UTC/, 'Z')
      self
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @string || @object.strftime('%Y-%m-%dT%H:%M:%S%Z').sub(/\+00:00|UTC/, 'Z')
    end
  end # class DateTime
end; end # class RDF::Literal
