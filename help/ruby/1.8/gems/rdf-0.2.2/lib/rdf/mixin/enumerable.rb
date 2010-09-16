module RDF
  ##
  # An RDF statement enumeration mixin.
  #
  # Classes that include this module must implement an `#each` method that
  # yields {RDF::Statement RDF statements}.
  #
  # @example Checking whether any statements exist
  #   enumerable.empty?
  #
  # @example Checking how many statements exist
  #   enumerable.count
  #
  # @example Checking whether a specific statement exists
  #   enumerable.has_statement?(RDF::Statement.new(subject, predicate, object))
  #   enumerable.has_triple?([subject, predicate, object])
  #   enumerable.has_quad?([subject, predicate, object, context])
  #
  # @example Checking whether a specific value exists
  #   enumerable.has_subject?(RDF::URI.new("http://rdf.rubyforge.org/"))
  #   enumerable.has_predicate?(RDF::DC.creator)
  #   enumerable.has_object?(RDF::Literal.new("Hello!", :language => :en))
  #   enumerable.has_context?(RDF::URI.new("http://rubyforge.org/"))
  #
  # @example Enumerating all statements
  #   enumerable.each_statement do |statement|
  #     puts statement.inspect
  #   end
  #
  # @example Enumerating all statements in the form of triples
  #   enumerable.each_triple do |subject, predicate, object|
  #     puts [subject, predicate, object].inspect
  #   end
  #
  # @example Enumerating all statements in the form of quads
  #   enumerable.each_quad do |subject, predicate, object, context|
  #     puts [subject, predicate, object, context].inspect
  #   end
  #
  # @example Enumerating all values
  #   enumerable.each_subject   { |value| puts value.inspect }
  #   enumerable.each_predicate { |value| puts value.inspect }
  #   enumerable.each_object    { |value| puts value.inspect }
  #   enumerable.each_context   { |value| puts value.inspect }
  #
  # @example Obtaining all statements
  #   enumerable.statements  #=> [RDF::Statement(subject1, predicate1, object1), ...]
  #   enumerable.triples     #=> [[subject1, predicate1, object1], ...]
  #   enumerable.quads       #=> [[subject1, predicate1, object1, context1], ...]
  #
  # @example Obtaining all unique values
  #   enumerable.subjects    #=> [subject1, subject2, subject3, ...]
  #   enumerable.predicates  #=> [predicate1, predicate2, predicate3, ...]
  #   enumerable.objects     #=> [object1, object2, object3, ...]
  #   enumerable.contexts    #=> [context1, context2, context3, ...]
  #
  # @see RDF::Graph
  # @see RDF::Repository
  module Enumerable
    extend  RDF::Util::Aliasing::LateBound
    include RDF::Countable
    include ::Enumerable

    ##
    # Returns all RDF statements.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @return [Enumerator<Statement>]
    # @see    #each_statement
    # @see    #enum_statement
    def statements(options = {})
      enum_statement
    end

    ##
    # Returns `true` if `self` contains the given RDF statement.
    #
    # @param  [Statement] statement
    # @return [Boolean]
    def has_statement?(statement)
      !enum_statement.find { |s| s.eql?(statement) }.nil?
    end

    alias_method :include?, :has_statement?

    ##
    # Iterates the given block for each RDF statement.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which statements are yielded is undefined.
    #
    # @overload each_statement
    #   @yield  [statement]
    #   @yieldparam [Statement] statement
    #   @return [void]
    #
    # @overload each_statement
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_statement
    def each_statement(&block)
      if block_given?
        # Invoke {#each} in the containing class:
        each(&block)
      else
        enum_statement
      end
    end

    ##
    # Returns an enumerator for {#each_statement}.
    #
    # @return [Enumerator]
    # @see    #each_statement
    def enum_statement
      enum_for(:each_statement).extend(RDF::Queryable, RDF::Enumerable)
    end

    alias_method :enum_statements, :enum_statement

    ##
    # Returns all RDF triples.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @return [Enumerator<Array(Resource, URI, Value)>]
    # @see    #each_triple
    # @see    #enum_triple
    def triples(options = {})
      enum_statement.map(&:to_triple).to_enum # TODO: optimize
    end

    ##
    # Returns `true` if `self` contains the given RDF triple.
    #
    # @param  [Array(Resource, URI, Value)] triple
    # @return [Boolean]
    def has_triple?(triple)
      enum_triple.include?(triple)
    end

    ##
    # Iterates the given block for each RDF triple.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which triples are yielded is undefined.
    #
    # @overload each_triple
    #   @yield  [subject, predicate, object]
    #   @yieldparam [Resource] subject
    #   @yieldparam [URI]      predicate
    #   @yieldparam [Value]    object
    #   @return [void]
    #
    # @overload each_triple
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_triple
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      else
        enum_triple
      end
    end

    ##
    # Returns an enumerator for {#each_triple}.
    #
    # @return [Enumerator]
    # @see    #each_triple
    def enum_triple
      enum_for(:each_triple)
    end

    alias_method :enum_triples, :enum_triple

    ##
    # Returns all RDF quads.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @return [Enumerator<Array(Resource, URI, Value, Resource)>]
    # @see    #each_quad
    # @see    #enum_quad
    def quads(options = {})
      enum_statement.map(&:to_quad).to_enum # TODO: optimize
    end

    ##
    # Returns `true` if `self` contains the given RDF quad.
    #
    # @param  [Array(Resource, URI, Value, Resource)] quad
    # @return [Boolean]
    def has_quad?(quad)
      enum_quad.include?(quad)
    end

    ##
    # Iterates the given block for each RDF quad.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which quads are yielded is undefined.
    #
    # @overload each_quad
    #   @yield  [subject, predicate, object, context]
    #   @yieldparam [Resource] subject
    #   @yieldparam [URI]      predicate
    #   @yieldparam [Value]    object
    #   @yieldparam [Resource] context
    #   @return [void]
    #
    # @overload each_quad
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_quad
    def each_quad(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_quad)
        end
      else
        enum_quad
      end
    end

    ##
    # Returns an enumerator for {#each_quad}.
    #
    # @return [Enumerator]
    # @see    #each_quad
    def enum_quad
      enum_for(:each_quad)
    end

    alias_method :enum_quads, :enum_quad

    ##
    # Returns all unique RDF subjects.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @option options [Boolean] :unique (true)
    # @return [Enumerator<Resource>]
    # @see    #each_subject
    # @see    #enum_subject
    def subjects(options = {})
      if options[:unique] == false
        enum_statement.map(&:subject).to_enum # TODO: optimize
      else
        enum_subject
      end
    end

    ##
    # Returns `true` if `self` contains the given RDF subject.
    #
    # @param  [Resource] value
    # @return [Boolean]
    def has_subject?(value)
      enum_subject.include?(value)
    end

    ##
    # Iterates the given block for each unique RDF subject.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which values are yielded is undefined.
    #
    # @overload each_subject
    #   @yield  [subject]
    #   @yieldparam [Resource] subject
    #   @return [void]
    #
    # @overload each_subject
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_subject
    def each_subject(&block)
      if block_given?
        values = {}
        each_statement do |statement|
          value = statement.subject
          unless value.nil? || values.include?(value.to_s)
            values[value.to_s] = true
            block.call(value)
          end
        end
      else
        enum_subject
      end
    end

    ##
    # Returns an enumerator for {#each_subject}.
    #
    # @return [Enumerator]
    # @see    #each_subject
    def enum_subject
      enum_for(:each_subject)
    end

    alias_method :enum_subjects, :enum_subject

    ##
    # Returns all unique RDF predicates.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @option options [Boolean] :unique (true)
    # @return [Enumerator<URI>]
    # @see    #each_predicate
    # @see    #enum_predicate
    def predicates(options = {})
      if options[:unique] == false
        enum_statement.map(&:predicate).to_enum # TODO: optimize
      else
        enum_predicate
      end
    end

    ##
    # Returns `true` if `self` contains the given RDF predicate.
    #
    # @param  [URI] value
    # @return [Boolean]
    def has_predicate?(value)
      enum_predicate.include?(value)
    end

    ##
    # Iterates the given block for each unique RDF predicate.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which values are yielded is undefined.
    #
    # @overload each_predicate
    #   @yield  [predicate]
    #   @yieldparam [URI] predicate
    #   @return [void]
    #
    # @overload each_predicate
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_predicate
    def each_predicate(&block)
      if block_given?
        values = {}
        each_statement do |statement|
          value = statement.predicate
          unless value.nil? || values.include?(value.to_s)
            values[value.to_s] = true
            block.call(value)
          end
        end
      else
        enum_predicate
      end
    end

    ##
    # Returns an enumerator for {#each_predicate}.
    #
    # @return [Enumerator]
    # @see    #each_predicate
    def enum_predicate
      enum_for(:each_predicate)
    end

    alias_method :enum_predicates, :enum_predicate

    ##
    # Returns all unique RDF objects.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @option options [Boolean] :unique (true)
    # @return [Enumerator<Value>]
    # @see    #each_object
    # @see    #enum_object
    def objects(options = {})
      if options[:unique] == false
        enum_statement.map(&:object).to_enum # TODO: optimize
      else
        enum_object
      end
    end

    ##
    # Returns `true` if `self` contains the given RDF object.
    #
    # @param  [Value] value
    # @return [Boolean]
    def has_object?(value)
      enum_object.include?(value)
    end

    ##
    # Iterates the given block for each unique RDF object.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which values are yielded is undefined.
    #
    # @overload each_object
    #   @yield  [object]
    #   @yieldparam [Value] object
    #   @return [void]
    #
    # @overload each_object
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_object
    def each_object(&block) # FIXME: deduplication
      if block_given?
        values = {}
        each_statement do |statement|
          value = statement.object
          unless value.nil? || values.include?(value)
            values[value] = true
            block.call(value)
          end
        end
      else
        enum_object
      end
    end

    ##
    # Returns an enumerator for {#each_object}.
    #
    # @return [Enumerator]
    # @see    #each_object
    def enum_object
      enum_for(:each_object)
    end

    alias_method :enum_objects, :enum_object

    ##
    # Returns all unique RDF contexts.
    #
    # @param  [Hash{Symbol => Boolean}] options
    # @option options [Boolean] :unique (true)
    # @return [Enumerator<Resource>]
    # @see    #each_context
    # @see    #enum_context
    def contexts(options = {})
      if options[:unique] == false
        enum_statement.map(&:context).to_enum # TODO: optimize
      else
        enum_context
      end
    end

    ##
    # Returns `true` if `self` contains the given RDF context.
    #
    # @param  [Resource] value
    # @return [Boolean]
    def has_context?(value)
      enum_context.include?(value)
    end

    ##
    # Iterates the given block for each unique RDF context.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which values are yielded is undefined.
    #
    # @overload each_context
    #   @yield  [context]
    #   @yieldparam [Resource] context
    #   @return [void]
    #
    # @overload each_context
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_context
    def each_context(&block)
      if block_given?
        values = {}
        each_statement do |statement|
          value = statement.context
          unless value.nil? || values.include?(value)
            values[value] = true
            block.call(value)
          end
        end
      else
        enum_context
      end
    end

    ##
    # Returns an enumerator for {#each_context}.
    #
    # @return [Enumerator]
    # @see    #each_context
    def enum_context
      enum_for(:each_context)
    end

    alias_method :enum_contexts, :enum_context

    ##
    # Iterates the given block for each RDF graph in `self`.
    #
    # If no block was given, returns an enumerator.
    #
    # The order in which graphs are yielded is undefined.
    #
    # @overload each_graph
    #   @yield  [graph]
    #   @yieldparam [RDF::Graph] graph
    #   @return [void]
    #
    # @overload each_graph
    #   @return [Enumerator]
    #
    # @return [void]
    # @see    #enum_graph
    # @since  0.1.9
    def each_graph(&block)
      if block_given?
        block.call(RDF::Graph.new(nil, :data => self))
        each_context do |context|
          block.call(RDF::Graph.new(context, :data => self))
        end
      else
        enum_graph
      end
    end

    ##
    # Returns an enumerator for {#each_graph}.
    #
    # @return [Enumerator]
    # @see    #each_graph
    # @since  0.1.9
    def enum_graph
      enum_for(:each_graph)
    end

    alias_method :enum_graphs, :enum_graph

    ##
    # Returns all RDF statements in `self` as an array.
    #
    # Mixes in `RDF::Enumerable` into the returned object.
    #
    # @return [Array]
    # @since  0.2.0
    def to_a
      super.extend(RDF::Enumerable)
    end

    ##
    # Returns all RDF statements in `self` as a set.
    #
    # Mixes in `RDF::Enumerable` into the returned object.
    #
    # @return [Set]
    # @since  0.2.0
    def to_set
      require 'set' unless defined?(::Set)
      super.extend(RDF::Enumerable)
    end

    ##
    # Returns all RDF objects indexed by their subjects and predicates.
    #
    # The return value is a `Hash` instance that has the structure:
    # `{subject => {predicate => [*objects]}}`.
    #
    # @return [Hash{Resource => Hash{URI => Array<Value>}}]
    def to_hash
      result = {}
      each_statement do |statement|
        next if statement.invalid? # skip any incomplete statements

        result[statement.subject] ||= {}
        values = (result[statement.subject][statement.predicate] ||= [])
        values << statement.object unless values.include?(statement.object)
      end
      result
    end

    ##
    # Returns a serialized string representation of `self`.
    #
    # Before calling this method you may need to explicitly require a
    # serialization plugin for the specified format.
    #
    # @example Serializing into N-Triples format
    #   require 'rdf/ntriples'
    #   ntriples = enumerable.dump(:ntriples)
    #
    # @param  [Array<Object>] args
    # @return [String]
    # @see    RDF::Writer.dump
    # @since  0.2.0
    def dump(*args)
      RDF::Writer.for(*args).dump(self)
    end
  end
end
