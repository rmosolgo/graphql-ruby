module GraphQL
  module StaticAnalysis
    class AnalysisError < GraphQL::Error
      # @param message [String]
      # @param nodes [Array<GraphQL::Language::Nodes::AbstractNode>]
      # @param fields [Array<String>]
      def initialize(message, nodes: [], fields: [])
        @nodes = nodes
        @fields = fields
        super(message)
      end

      def to_h
        {
          "message" => message,
          "locations" => @nodes.map { |n| { "line" => n.line, "column" => n.col } },
          "fields" => @fields,
        }
      end
    end
  end
end
