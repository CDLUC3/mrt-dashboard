module RDF; class Literal
  ##
  # A boolean literal.
  #
  # @see   http://www.w3.org/TR/xmlschema-2/#boolean
  # @since 0.2.1
  class Boolean < Literal
    DATATYPE = XSD.boolean
    GRAMMAR  = /^(true|false|1|0)$/i.freeze
    TRUES    = %w(true  1).freeze
    FALSES   = %w(false 0).freeze

    ##
    # @param  [Boolean] value
    # @option options [String] :lexical (nil)
    def initialize(value, options = {})
      @datatype = RDF::URI(options[:datatype] || DATATYPE)
      @string   = options[:lexical] if options.has_key?(:lexical)
      @string   = value if !defined?(@string) && value.is_a?(String)
      @object   = case
        when true.equal?(value)  then true
        when false.equal?(value) then false
        when TRUES.include?(value.to_s.downcase)  then true
        when FALSES.include?(value.to_s.downcase) then false
        else value
      end
    end

    ##
    # Converts the literal into its canonical lexical representation.
    #
    # @return [Literal]
    # @see    http://www.w3.org/TR/xmlschema-2/#boolean
    def canonicalize
      @string = (@object ? :true : :false).to_s
      self
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @string || @object.to_s
    end

    ##
    # Returns `true` if this value is `true`.
    #
    # @return [Boolean]
    def true?
      @object.equal?(true)
    end

    ##
    # Returns `true` if this value is `false`.
    #
    # @return [Boolean]
    def false?
      @object.equal?(false)
    end
  end # class Boolean
end; end # class RDF::Literal
