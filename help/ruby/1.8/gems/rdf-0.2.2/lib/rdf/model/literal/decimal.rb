module RDF; class Literal
  ##
  # A decimal literal.
  #
  # @see   http://www.w3.org/TR/xmlschema-2/#decimal
  # @since 0.2.1
  class Decimal < Literal
    DATATYPE = XSD.decimal
    GRAMMAR  = /^[\+\-]?\d+(\.\d*)?$/.freeze

    ##
    # @param  [BigDecimal] value
    # @option options [String] :lexical (nil)
    def initialize(value, options = {})
      @datatype = RDF::URI(options[:datatype] || DATATYPE)
      @string   = options[:lexical] if options.has_key?(:lexical)
      @string   = value if !defined?(@string) && value.is_a?(String)
      @object   = case
        when value.is_a?(BigDecimal) then value
        else BigDecimal(value.to_s)
      end
    end

    ##
    # Converts the literal into its canonical lexical representation.
    #
    # @return [Literal]
    # @see    http://www.w3.org/TR/xmlschema-2/#decimal
    def canonicalize
      # Can't use simple %f transformation due to special requirements from
      # N3 tests in representation
      @string = begin
        i, f = @object.to_s('F').split('.')
        i.sub!(/^\+?0+(\d)$/, '\1') # remove the optional leading '+' sign and any extra leading zeroes
        f = f[0, 16]                # truncate the fractional part after 15 decimal places
        f.sub!(/0*$/, '')           # remove any trailing zeroes
        f = '0' if f.empty?         # ...but there must be a digit to the right of the decimal point
        "#{i}.#{f}"
      end
      self
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    # @see    BigDecimal#to_s
    def to_s
      @string || @object.to_s('F')
    end

    ##
    # Returns the value as an integer.
    #
    # @return [Integer]
    # @see    BigDecimal#to_i
    def to_i
      @object.to_i
    end

    ##
    # Returns the value as a floating point number.
    #
    # The usual accuracy limits and errors of binary float arithmetic apply.
    #
    # @return [Float]
    # @see    BigDecimal#to_f
    def to_f
      @object.to_f
    end

    ##
    # Returns the value as a decimal number.
    #
    # @return [BigDecimal]
    # @see    BigDecimal#to_d
    def to_d
      @object.respond_to?(:to_d) ? @object.to_d : BigDecimal(@object.to_s)
    end

    ##
    # Returns the value as a rational number.
    #
    # @return [Rational]
    # @see    BigDecimal#to_r
    def to_r
      @object.to_r # only available on Ruby 1.9+
    end
  end # class Decimal
end; end # class RDF::Literal
