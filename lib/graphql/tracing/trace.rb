# frozen_string_literal: true

require "graphql/tracing"

module GraphQL
  module Tracing
    # This is the base class for a `trace` instance whose methods are called during query execution.
    # "Trace modes" are subclasses of this with custom tracing modules mixed in.
    #
    # A trace module may implement any of the methods on `Trace`, being sure to call `super`
    # to continue any tracing hooks and call the actual runtime behavior.
    #
    class Trace
      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex, nil`)
      # - `query` (`GraphQL::Query, nil`)
      #
      # :call-seq:
      #   initialize(GraphQL::Execution::Multiplex | nil multiplex:, GraphQL::Query | nil query:, **_options)
      def initialize(multiplex: nil, query: nil, **_options)
        @multiplex = multiplex
        @query = query
      end

      # The Ruby parser doesn't call this method (`graphql/c_parser` does.)
      def lex(query_string:)
        yield
      end

      # **Parameters**
      #
      # - `query_string` (`String`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   parse(String query_string:) -> void
      def parse(query_string:)
        yield
      end

      def validate(query:, validate:)
        yield
      end

      def begin_validate(query, validate)
      end

      def end_validate(query, validate, errors)
      end

      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex`)
      # - `analyzers` (`Array<Class>`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   begin_analyze_multiplex(GraphQL::Execution::Multiplex multiplex, Array[Class] analyzers) -> void
      def begin_analyze_multiplex(multiplex, analyzers); end
      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex`)
      # - `analyzers` (`Array<Class>`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   end_analyze_multiplex(GraphQL::Execution::Multiplex multiplex, Array[Class] analyzers) -> void
      def end_analyze_multiplex(multiplex, analyzers); end
      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   analyze_multiplex(GraphQL::Execution::Multiplex multiplex:) -> void
      def analyze_multiplex(multiplex:)
        yield
      end

      def analyze_query(query:)
        yield
      end

      # This wraps an entire `.execute` call.
      #
      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   execute_multiplex(GraphQL::Execution::Multiplex multiplex:) -> void
      def execute_multiplex(multiplex:)
        yield
      end

      def execute_query(query:)
        yield
      end

      def execute_query_lazy(query:, multiplex:)
        yield
      end

      # GraphQL is about to resolve this field
      #
      # **Parameters**
      #
      # - `field` (`GraphQL::Schema::Field`)
      # - `object` (`GraphQL::Schema::Object`)
      # - `arguments` (`Hash`)
      # - `query` (`GraphQL::Query`)
      #
      # :call-seq:
      #   begin_execute_field(GraphQL::Schema::Field field, GraphQL::Schema::Object object, Hash arguments, GraphQL::Query query)
      def begin_execute_field(field, object, arguments, query); end
      # GraphQL just finished resolving this field
      #
      # **Parameters**
      #
      # - `field` (`GraphQL::Schema::Field`)
      # - `object` (`GraphQL::Schema::Object`)
      # - `arguments` (`Hash`)
      # - `query` (`GraphQL::Query`)
      # - `result` (`Object`)
      #
      # :call-seq:
      #   end_execute_field(GraphQL::Schema::Field field, GraphQL::Schema::Object object, Hash arguments, GraphQL::Query query, Object result)
      def end_execute_field(field, object, arguments, query, result); end

      def execute_field(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:)
        yield
      end

      def authorized(query:, type:, object:)
        yield
      end

      def objects(type, object, context)
      end

      def object_loaded(argument_definition, object, context)
      end

      # A call to `.authorized?` is starting
      #
      # **Parameters**
      #
      # - `type` (`Class<GraphQL::Schema::Object>`)
      # - `object` (`Object`)
      # - `context` (`GraphQL::Query::Context`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   begin_authorized(Class[GraphQL::Schema::Object] type, Object object, GraphQL::Query::Context context) -> void
      def begin_authorized(type, object, context)
      end
      # A call to `.authorized?` just finished
      #
      # **Parameters**
      #
      # - `type` (`Class<GraphQL::Schema::Object>`)
      # - `object` (`Object`)
      # - `context` (`GraphQL::Query::Context`)
      # - `authorized_result` (`Boolean`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   end_authorized(Class[GraphQL::Schema::Object] type, Object object, GraphQL::Query::Context context, bool authorized_result) -> void
      def end_authorized(type, object, context, authorized_result)
      end

      def authorized_lazy(query:, type:, object:)
        yield
      end

      def resolve_type(query:, type:, object:)
        yield
      end

      def resolve_type_lazy(query:, type:, object:)
        yield
      end

      # A call to `.resolve_type` is starting
      #
      # **Parameters**
      #
      # - `type` (`Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>`)
      # - `value` (`Object`)
      # - `context` (`GraphQL::Query::Context`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   begin_resolve_type(Class[GraphQL::Schema::Union] | Module[GraphQL::Schema::Interface] type, Object value, GraphQL::Query::Context context) -> void
      def begin_resolve_type(type, value, context)
      end

      # A call to `.resolve_type` just ended
      #
      # **Parameters**
      #
      # - `type` (`Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>`)
      # - `value` (`Object`)
      # - `context` (`GraphQL::Query::Context`)
      # - `resolved_type` (`Class<GraphQL::Schema::Object>`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   end_resolve_type(Class[GraphQL::Schema::Union] | Module[GraphQL::Schema::Interface] type, Object value, GraphQL::Query::Context context, Class[GraphQL::Schema::Object] resolved_type) -> void
      def end_resolve_type(type, value, context, resolved_type)
      end

      # A dataloader run is starting
      #
      # **Parameters**
      #
      # - `dataloader` (`GraphQL::Dataloader`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   begin_dataloader(GraphQL::Dataloader dataloader) -> void
      def begin_dataloader(dataloader); end
      # A dataloader run has ended
      #
      # **Parameters**
      #
      # - `dataloder` (`GraphQL::Dataloader`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   end_dataloader(dataloader) -> void
      def end_dataloader(dataloader); end

      # A source with pending keys is about to fetch
      #
      # **Parameters**
      #
      # - `source` (`GraphQL::Dataloader::Source`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   begin_dataloader_source(GraphQL::Dataloader::Source source) -> void
      def begin_dataloader_source(source); end
      # A fetch call has just ended
      #
      # **Parameters**
      #
      # - `source` (`GraphQL::Dataloader::Source`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   end_dataloader_source(GraphQL::Dataloader::Source source) -> void
      def end_dataloader_source(source); end

      # Called when Dataloader spins up a new fiber for GraphQL execution
      #
      # **Parameters**
      #
      # - `jobs` (`Array<#call>`) — Execution steps to run
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   dataloader_spawn_execution_fiber(Array[#call] jobs) -> void
      def dataloader_spawn_execution_fiber(jobs); end
      # Called when Dataloader spins up a new fiber for fetching data
      #
      # **Parameters**
      #
      # - `pending_sources` (`GraphQL::Dataloader::Source`) — Instances with pending keys
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   dataloader_spawn_source_fiber(GraphQL::Dataloader::Source pending_sources) -> void
      def dataloader_spawn_source_fiber(pending_sources); end
      # Called when an execution or source fiber terminates
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   dataloader_fiber_exit;() -> void
      def dataloader_fiber_exit; end

      # Called when a Dataloader fiber is paused to wait for data
      #
      # **Parameters**
      #
      # - `source` (`GraphQL::Dataloader::Source`) — The Source whose `load` call initiated this `yield`
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   dataloader_fiber_yield(GraphQL::Dataloader::Source source) -> void
      def dataloader_fiber_yield(source); end
      # Called when a Dataloader fiber is resumed because data has been loaded
      #
      # **Parameters**
      #
      # - `source` (`GraphQL::Dataloader::Source`) — The Source whose `load` call previously caused this Fiber to wait
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   dataloader_fiber_resume(GraphQL::Dataloader::Source source) -> void
      def dataloader_fiber_resume(source); end
    end
  end
end
