module GraphQL
  module StaticAnalysis
    class AnalysisError < GraphQL::Error
      def initialize(message, nodes: [])
        @nodes = nodes
        super(message)
      end

      def to_h
        {
          "message" => message,
          "path" => [], # TODO: track the logical path to the error
          "locations" => @nodes.map { |n| { "column" => n.col, "line" => n.line } }
        }
      end
    end
  end
end
