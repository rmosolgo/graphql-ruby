module GraphQL
  module Execution
    # This is the info for resolving a single field
    class Frame
      extend Forwardable
      attr_reader :query, :type, :irep_node

      def initialize(query:, irep_node:, type: )
        @query = query
        @type = type
        @irep_node = irep_node
      end

      def field
        @field ||= query.get_field(type, irep_node.definition_name)
      end

      def ast_node
        irep_node.ast_node
      end

      def path
        irep_node.path
      end

      def context
        @context ||= query.context
      end

      def add_error(err)
        if err.is_a?(GraphQL::ExecutionError)
          err.ast_node = ast_node
          err.path = path
        end
        context.errors << err
        nil
      end

      def spawn(**kwargs)
        next_kwargs = {query: @query, irep_node: @irep_node, type: @type}
        next_kwargs.merge!(kwargs)
        self.class.new(next_kwargs)
      end

      def_delegators :context, :[], :[]=
    end
  end
end
