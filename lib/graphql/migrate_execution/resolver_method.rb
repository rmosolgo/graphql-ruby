# frozen_string_literal: true
module GraphQL
  class MigrateExecution

    class ResolverMethod
      def initialize(name, node)
        @name = name
        @node = node
        @parameter_names = if node.parameters
          node.parameters.keywords.map(&:name)
        else
          []
        end
        @self_sends = Set.new
        @calls_object = false
        @calls_context = false
        @calls_class = false
        @calls_dataloader = false
        @dataloader_call = false
      end

      attr_reader :name, :node, :parameter_names, :self_sends

      attr_reader :source_class_node, :source_arg_nodes, :load_arg_node, :dataload_association

      attr_accessor :calls_object, :calls_context, :calls_class, :calls_dataloader

      attr_accessor :dataloader_call

      def source
        node.location.slice_lines
      end

      def migration_strategy
        calls_to_self = self_sends.to_a
        if @calls_context
          calls_to_self.delete(:context)
        end
        if @calls_object
          calls_to_self.delete(:object)
        end

        calls_to_self.delete(:dataloader)
        calls_to_self.delete(:dataload_association)
        calls_to_self.delete(:dataload_record)
        calls_to_self.delete(:dataload)

        # Global-ish methods:
        calls_to_self.delete(:raise)

        # Locals:
        calls_to_self -= @parameter_names

        if calls_to_self.empty?
          if calls_dataloader
            if !dataloader_call
              return DataloaderManual
            end

            call_node = node.body.body.first
            case call_node.name
            when :dataload
              @source_class_node = call_node.arguments.arguments.first
              @source_arg_nodes = call_node.arguments.arguments[1...-1]
              @load_arg_node = call_node.arguments.arguments.last
            when :dataload_association
              if (assoc_args = call_node.arguments.arguments).size == 1 &&
                  ((assoc_arg = assoc_args.first).is_a?(Prism::SymbolNode))
                assoc_sym = assoc_arg.unescaped.to_sym
                @dataload_association = assoc_sym == name ? true : assoc_sym
              end
            else
              if (source_call = call_node.receiver) # eg dataloader.with(...).load(...)
                @source_class_node = source_call.arguments.arguments.first
                @source_arg_nodes = source_call.arguments.arguments[1..-1]
                @load_arg_node = call_node.arguments.arguments.last
              end
            end

            input_is_object = @load_arg_node.is_a?(Prism::CallNode) && @load_arg_node.name == :object
            # Guess whether these args are free of runtime context:
            shortcutable_source_args = @source_arg_nodes && (@source_arg_nodes.empty? || (@source_arg_nodes.all? { |a| Visitor.constant_node?(a) }))
            if @source_class_node.is_a?(Prism::ConstantPathNode) && shortcutable_source_args && input_is_object
              DataloaderShorthand
            else
              case call_node.name
              when :load, :request, :dataload
                DataloaderAll
              when :load_all, :request_all, :dataload_record
                DataloaderBatch
              when :dataload_association
                DataloaderShorthand
              else
                DataloaderManual
              end
            end
          elsif calls_object
            ResolveEach
          else
            ResolveStatic
          end
        else
          NotImplemented
        end
      end
    end
  end
end
