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
            when :load, :request, :dataload
              DataloadAll
            when :load_all, :request_all, :dataload_record
              DataloaderBatch
            when :dataload_association
              DataloaderAssociation
            else
              DataloaderManual
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
