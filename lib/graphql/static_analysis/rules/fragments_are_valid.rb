module GraphQL
  module StaticAnalysis
    module Rules
      # Implements some validations from the GraphQL spec:
      #
      # - Fragments Must be Used
      # - Fragment Spread Target is Present
      # - Fragment Spreads are Finite
      class FragmentsAreValid
        def initialize(analysis)
          @analysis = analysis
        end

        def errors
          dependency_map = @analysis.dependencies

          errs = []
          if dependency_map.cyclical_definitions.any?
            defn_names = dependency_map.cyclical_definitions.map { |n| n.name || "anonymous query" }.join(", ")
            errs << AnalysisError.new(
                "Some definitions contain cycles: #{defn_names}",
                nodes: dependency_map.cyclical_definitions,
              )
          end

          dependency_map.unmet_dependencies.each do |op_defn, spreads|
            errs << AnalysisError.new(
              "#{op_defn.name || "Query" } uses undefined fragments: #{spreads.map(&:name).join(", ")}",
              nodes: spreads,
            )
          end

          if dependency_map.unused_dependencies.any?
            errs << AnalysisError.new(
              "Fragments are defined but unused: #{dependency_map.unused_dependencies.map(&:name).join(", ")}",
              nodes: dependency_map.unused_dependencies,
            )
          end

          errs
        end
      end
    end
  end
end
