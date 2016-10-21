module GraphQL
  module StaticAnalysis
    module Rules
      # Implements some validations from the GraphQL spec:
      #
      # - Operation Name Uniqueness
      # - Lone Anonymous Operation
      # - Fragment Name Uniqueness
      class DefinitionNamesAreValid
        def initialize(analysis)
          @analysis = analysis
        end

        def errors
          definition_names = @analysis.definition_names
          errs = []
          anonymous_op_count = definition_names.anonymous_operations.length
          operation_names = definition_names.named_operations.length

          if anonymous_op_count > 1
            errs << AnalysisError.new(
            "A document must not have more than one anonymous operation",
            nodes: definition_names.anonymous_operations,
            )
          end

          if anonymous_op_count > 0 && operation_names > 0
            errs << AnalysisError.new(
            "A document must not mix anonymous operations with named operations",
            nodes: definition_names.anonymous_operations,
            )
          end

          definition_names.named_operations.each do |name, named_ops|
            if named_ops.length > 1
              errs << AnalysisError.new(
              "Operation names must be unique, but #{name} is not unique",
              nodes: named_ops,
              )
            end
          end

          definition_names.fragment_definitions.each do |name, fragment_defns|
            if fragment_defns.length > 1
              errs << AnalysisError.new(
              "Fragment names must be unique, but #{name} is not unique",
              nodes: fragment_defns,
              )
            end
          end

          errs
        end
      end
    end
  end
end
