module RDF; class Query
  ##
  # An RDF query pattern.
  class Pattern < RDF::Statement
    ##
    # @private
    # @since 0.2.2
    def self.from(pattern)
      case pattern
        when Pattern   then pattern
        when Statement then self.new(pattern.to_hash)
        when Hash      then self.new(pattern)
        when Array     then self.new(*pattern)
        else raise ArgumentError.new("expected RDF::Query::Pattern, RDF::Statement, Hash, or Array, but got #{pattern.inspect}")
      end
    end

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    ##
    # @overload initialize(options = {})
    #   @param  [Hash{Symbol => Object}]     options
    #   @option options [Variable, Resource] :subject   (nil)
    #   @option options [Variable, URI]      :predicate (nil)
    #   @option options [Variable, Value]    :object    (nil)
    #   @option options [Variable, Resource] :context   (nil)
    #   @option options [Boolean]            :optional  (false)
    #
    # @overload initialize(subject, predicate, object, options = {})
    #   @param  [Variable, Resource]         subject
    #   @param  [Variable, URI]              predicate
    #   @param  [Variable, Value]            object
    #   @param  [Hash{Symbol => Object}]     options
    #   @option options [Variable, Resource] :context   (nil)
    #   @option options [Boolean]            :optional  (false)
    def initialize(subject = nil, predicate = nil, object = nil, options = {})
      super
    end

    ##
    # @private
    def initialize!
      @context   = Variable.new(@context)   if @context.is_a?(Symbol)
      @subject   = Variable.new(@subject)   if @subject.is_a?(Symbol)
      @predicate = Variable.new(@predicate) if @predicate.is_a?(Symbol)
      @object    = Variable.new(@object)    if @object.is_a?(Symbol)
      super
    end

    ##
    # @param  [Graph, Repository] graph
    # @return [Enumerator]
    def execute(graph, &block)
      graph.query(self) # FIXME
    end

    ##
    # Returns `true` if this pattern contains variables.
    #
    # @return [Boolean]
    def variables?
      subject.is_a?(Variable) ||
        predicate.is_a?(Variable) ||
        object.is_a?(Variable)
    end

    ##
    # Returns the number of variables in this pattern.
    #
    # @return [Integer] (0..3)
    def variable_count
      variables.size
    end

    alias_method :cardinality, :variable_count
    alias_method :arity,       :variable_count

    ##
    # Returns all variables in this pattern.
    #
    # @return [Hash{Symbol => Variable}]
    def variables
      variables = {}
      variables.merge!(subject.variables)   if subject.is_a?(Variable)
      variables.merge!(predicate.variables) if predicate.is_a?(Variable)
      variables.merge!(object.variables)    if object.is_a?(Variable)
      variables
    end

    ##
    # Returns `true` if this pattern contains bindings.
    #
    # @return [Boolean]
    def bindings?
      !bindings.empty?
    end

    ##
    # Returns the number of bindings in this pattern.
    #
    # @return [Integer] (0..3)
    def binding_count
      bindings.size
    end

    ##
    # Returns all bindings in this pattern.
    #
    # @return [Hash{Symbol => Value}]
    def bindings
      bindings = {}
      bindings.merge!(subject.bindings)   if subject.is_a?(Variable)
      bindings.merge!(predicate.bindings) if predicate.is_a?(Variable)
      bindings.merge!(object.bindings)    if object.is_a?(Variable)
      bindings
    end

    ##
    # Returns `true` if all variables in this pattern are bound.
    #
    # @return [Boolean]
    def bound?
      !variables.empty? && variables.values.all?(&:bound?)
    end

    ##
    # Returns all bound variables in this pattern.
    #
    # @return [Hash{Symbol => Variable}]
    def bound_variables
      variables.reject { |name, variable| variable.unbound? }
    end

    ##
    # Returns `true` if all variables in this pattern are unbound.
    #
    # @return [Boolean]
    def unbound?
      !variables.empty? && variables.values.all?(&:unbound?)
    end

    ##
    # Returns all unbound variables in this pattern.
    #
    # @return [Hash{Symbol => Variable}]
    def unbound_variables
      variables.reject { |name, variable| variable.bound? }
    end

    ##
    # Returns the string representation of this pattern.
    #
    # @return [String]
    def to_s
      require 'stringio' unless defined?(StringIO)
      StringIO.open do |buffer| # FIXME in RDF::Statement
        buffer << (subject.is_a?(Variable)   ? subject.to_s :   "<#{subject}>") << ' '
        buffer << (predicate.is_a?(Variable) ? predicate.to_s : "<#{predicate}>") << ' '
        buffer << (object.is_a?(Variable)    ? object.to_s :    "<#{object}>") << ' .'
        buffer.string
      end
    end
  end # class Pattern
end; end # module RDF class Query
