# frozen_string_literal: true
module GraphQL
  class Query
    # Contain the validation pipeline and expose the results.
    #
    # 0. Checks in {Query#initialize}:
    #   - Rescue a ParseError, halt if there is one
    #   - Check for selected operation, halt if not found
    # 1. Validate the AST, halt if errors
    # 2. Validate the variables, halt if errors
    # 3. Run query analyzers, halt if errors
    #
    # {#valid?} is false if any of the above checks halted the pipeline.
    #
    # @api private
    class ValidationPipeline
      def initialize(query:, validate:, parse_error:, operation_name_error:, max_depth:, max_complexity:)
        @validation_errors = []
        @analysis_errors = []
        @internal_representation = nil
        @validate = validate
        @parse_error = parse_error
        @operation_name_error = operation_name_error
        @query = query
        @schema = query.schema
        @max_depth = max_depth
        @max_complexity = max_complexity

        @has_validated = false
      end

      # @return [Boolean] does this query have errors that should prevent it from running?
      def valid?
        ensure_has_validated
        @valid
      end

      # @return [Array<GraphQL::AnalysisError>] Errors for this particular query run (eg, exceeds max complexity)
      def analysis_errors
        ensure_has_validated
        @analysis_errors
      end

      # @return [Array<GraphQL::StaticValidation::Message>] Static validation errors for the query string
      def validation_errors
        ensure_has_validated
        @validation_errors
      end

      # @return [Hash<String, nil => GraphQL::InternalRepresentation::Node] Operation name -> Irep node pairs
      def internal_representation
        ensure_has_validated
        @internal_representation
      end

      def analyzers
        ensure_has_validated
        @query_analyzers
      end

      private

      # If the pipeline wasn't run yet, run it.
      # If it was already run, do nothing.
      def ensure_has_validated
        return if @has_validated
        @has_validated = true

        if @parse_error
          # This is kind of crazy: we push the parse error into `ctx`
          # in {DefaultParseError} so that users can _opt out_ by redefining that hook.
          # That means we can't _re-add_ the error here (otherwise we'd either
          # add it twice _or_ override the user's choice to not add it).
          # So we just have to know that it was invalid and go from there.
          @valid = false
          return
        elsif @operation_name_error
          @validation_errors << @operation_name_error
        else
          validation_result = @schema.static_validator.validate(@query, validate: @validate)
          @validation_errors.concat(validation_result[:errors])
          @internal_representation = validation_result[:irep]

          if @validation_errors.none?
            @validation_errors.concat(@query.variables.errors)
          end

          if @validation_errors.none?
            @query_analyzers = build_analyzers(@schema, @max_depth, @max_complexity)
            # if query_analyzers.any?
            #   analysis_results = GraphQL::Analysis.analyze_query(@query, query_analyzers)
            #   @analysis_errors = analysis_results
            #     .flatten # accept n-dimensional array
            #     .select { |r| r.is_a?(GraphQL::AnalysisError) }
            # end
          end
        end

        @valid = @validation_errors.none? && @analysis_errors.none?
      end

      # If there are max_* values, add them,
      # otherwise reuse the schema's list of analyzers.
      def build_analyzers(schema, max_depth, max_complexity)
        if max_depth || max_complexity
          qa = schema.query_analyzers.dup
          if max_depth
            qa << GraphQL::Analysis::MaxQueryDepth.new(max_depth)
          end
          if max_complexity
            qa << GraphQL::Analysis::MaxQueryComplexity.new(max_complexity)
          end
          qa
        else
          schema.query_analyzers
        end
      end
    end
  end
end
