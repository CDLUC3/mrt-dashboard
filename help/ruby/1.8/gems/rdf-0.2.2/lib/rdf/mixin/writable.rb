module RDF
  ##
  module Writable
    extend RDF::Util::Aliasing::LateBound

    ##
    # Returns `true` if `self` is writable.
    #
    # @return [Boolean]
    # @see    RDF::Readable#readable?
    def writable?
      true
    end

    ##
    # Inserts RDF data into `self`.
    #
    # @param  [RDF::Enumerable, RDF::Statement, #to_rdf] data
    # @return [Writable]
    def <<(data)
      case data
        when RDF::Graph
          insert_graph(data)
        when RDF::Enumerable
          insert_statements(data)
        when RDF::Statement
          insert_statement(data)
        else case
          when data.respond_to?(:to_rdf) && !data.equal?(rdf = data.to_rdf)
            self << rdf
          else
            insert_statement(create_statement(data))
        end
      end

      return self
    end

    ##
    # Inserts RDF statements into `self`.
    #
    # @param  [Array<RDF::Statement>] statements
    # @return [Writable]
    def insert(*statements)
      statements.map! do |value|
        case
          when value.respond_to?(:each_statement)
            insert_statements(value)
            nil
          when (statement = create_statement(value)).valid?
            statement
          else
            raise ArgumentError.new("not a valid statement: #{value.inspect}")
        end
      end
      statements.compact!
      insert_statements(statements) unless statements.empty?

      return self
    end

    alias_method :insert!, :insert

  protected

    ##
    # Inserts the given RDF graph into the underlying storage or output
    # stream.
    #
    # Defaults to passing the graph to the {#insert_statements} method.
    #
    # Subclasses of {RDF::Repository} may wish to override this method in
    # case their underlying storage architecture is graph-centric rather
    # than statement-oriented.
    #
    # Subclasses of {RDF::Writer} may wish to override this method if the
    # output format they implement supports named graphs, in which case
    # implementing this method may help in producing prettier and more
    # concise output.
    #
    # @param  [RDF::Graph] graph
    # @return [void]
    def insert_graph(graph)
      insert_statements(graph)
    end

    ##
    # Inserts the given RDF statements into the underlying storage or output
    # stream.
    #
    # Defaults to invoking {#insert_statement} for each given statement.
    #
    # Subclasses of {RDF::Repository} may wish to override this method if
    # they are capable of more efficiently inserting multiple statements at
    # once.
    #
    # Subclasses of {RDF::Writer} don't generally need to implement this
    # method.
    #
    # @param  [RDF::Enumerable] statements
    # @return [void]
    def insert_statements(statements)
      each = statements.respond_to?(:each_statement) ? :each_statement : :each
      statements.__send__(each) do |statement|
        insert_statement(statement)
      end
    end

    ##
    # Inserts an RDF statement into the underlying storage or output stream.
    #
    # Subclasses of {RDF::Repository} must implement this method, except if
    # they are immutable.
    #
    # Subclasses of {RDF::Writer} must implement this method.
    #
    # @param  [RDF::Statement] statement
    # @return [void]
    # @abstract
    def insert_statement(statement)
      raise NotImplementedError.new("#{self.class}#insert_statement")
    end

    ##
    # Transforms various input into an `RDF::Statement` instance.
    #
    # @param  [RDF::Statement, Hash, Array, #to_a] statement
    # @return [RDF::Statement]
    # @deprecated
    def create_statement(statement)
      Statement.from(statement)
    end

    protected :insert_statements
    protected :insert_statement
    protected :create_statement
  end
end
