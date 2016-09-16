module GraphQL
  module StaticAnalysis
    module Rules
      # Implements some validations from the GraphQL spec:
      #
      # - Variable Uniqueness within Operation
      # - Variable Uses are Defined
      # - Variables are Used
      class VariableUsagesAreValid
        def initialize(analysis)
          @analysis = analysis
        end

        def errors
          usage_map = @analysis.variable_usages
          errs = []
          usage_map.each do |operation, variables|
            variables[:defined].each do |name, definitions|
              if definitions.length > 1
                errs << AnalysisError.new(
                  "Variable name must be unique: $#{name}",
                  nodes: definitions,
                )
              end

              usages = variables[:used][name]
              if usages.length == 0
                errs << AnalysisError.new(
                  "Variable must be used: $#{name}",
                  nodes: definitions,
                )
              end
            end

            variables[:used].each do |name, usages|
              if variables[:defined][name].length == 0
                errs << AnalysisError.new(
                  "Variable must be defined: $#{name}",
                  nodes: usages,
                )
              end
            end
          end
          errs
        end
      end
    end
  end
end
