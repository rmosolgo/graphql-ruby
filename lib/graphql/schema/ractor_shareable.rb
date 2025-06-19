# frozen_string_literal: true
module GraphQL
  class Schema
    module RactorShareable
      def self.extended(schema_class)
        schema_class.extend(SchemaExtension)
        schema_class.freeze_schema
      end

      module SchemaExtension

        def freeze_error_handlers(handlers)
          handlers[:subclass_handlers].default_proc = nil
          handlers[:subclass_handlers].each do |_class, subclass_handlers|
            freeze_error_handlers(subclass_handlers)
          end
          Ractor.make_shareable(handlers)
        end

        def freeze_schema
          # warm some ivars:
          default_analysis_engine
          default_execution_strategy
          GraphQL.default_parser
          default_logger
          freeze_error_handlers(error_handlers)
          # TODO: this freezes errors of parent classes which could cause trouble
          parent_class = superclass
          while parent_class.respond_to?(:error_handlers)
            freeze_error_handlers(parent_class.error_handlers)
            parent_class = parent_class.superclass
          end

          own_tracers.freeze
          @frozen_tracers = tracers.freeze
          own_trace_modes.each do |m|
            trace_options_for(m)
            build_trace_mode(m)
          end
          build_trace_mode(:default)
          Ractor.make_shareable(@trace_options_for_mode)
          Ractor.make_shareable(own_trace_modes)
          Ractor.make_shareable(own_multiplex_analyzers)
          @frozen_multiplex_analyzers = Ractor.make_shareable(multiplex_analyzers)
          Ractor.make_shareable(own_query_analyzers)
          @frozen_query_analyzers = Ractor.make_shareable(query_analyzers)
          Ractor.make_shareable(own_plugins)
          own_plugins.each do |(plugin, options)|
            Ractor.make_shareable(plugin)
            Ractor.make_shareable(options)
          end
          @frozen_plugins = Ractor.make_shareable(plugins)
          Ractor.make_shareable(own_references_to)
          @frozen_directives = Ractor.make_shareable(directives)

          Ractor.make_shareable(visibility)
          Ractor.make_shareable(introspection_system)
          extend(FrozenMethods)

          Ractor.make_shareable(self)
          superclass.respond_to?(:freeze_schema) && superclass.freeze_schema
        end

        module FrozenMethods
          def tracers; @frozen_tracers; end
          def multiplex_analyzers; @frozen_multiplex_analyzers; end
          def query_analyzers; @frozen_query_analyzers; end
          def plugins; @frozen_plugins; end
          def directives; @frozen_directives; end

          # This actually accumulates info during execution...
          # How to support it?
          def lazy?(_obj); false; end
          def sync_lazy(obj); obj; end
        end
      end
    end
  end
end
