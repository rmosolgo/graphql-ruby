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
      attr_reader :max_depth, :max_complexity

      def initialize(query:, validate:, parse_error:, operation_name_error:, max_depth:, max_complexity:)
        @validation_errors = []
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

      # @return [Array<GraphQL::StaticValidation::Error, GraphQL::Query::VariableValidationError>] Static validation errors for the query string
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
          validation_result = @schema.static_validator.validate(@query, validate: @validate, timeout: @schema.validate_timeout)
          @validation_errors.concat(validation_result[:errors])
          @internal_representation = validation_result[:irep]

          if @validation_errors.empty?
            @validation_errors.concat(@query.variables.errors)
          end

          if @validation_errors.empty?
            @query_analyzers = build_analyzers(
              @schema,
              @max_depth,
              @max_complexity
            )
          end
        end

        @valid = @validation_errors.empty?
      rescue SystemStackError => err
        @valid = false
        @schema.query_stack_error(@query, err)
      end

      # If there are max_* values, add them,
      # otherwise reuse the schema's list of analyzers.
      def build_analyzers(schema, max_depth, max_complexity)
        qa = schema.query_analyzers.dup

        # Filter out the built in authorization analyzer.
        # It is deprecated and does not have an AST analyzer alternative.
        qa = qa.select do |analyzer|
          if analyzer == GraphQL::Authorization::Analyzer && schema.using_ast_analysis?
            raise "The Authorization analyzer is not supported with AST Analyzers"
          else
            true
          end
        end

        if max_depth || max_complexity
          # Depending on the analysis engine, we must use different analyzers
          # remove this once everything has switched over to AST analyzers
          if schema.using_ast_analysis?
            if max_depth
              qa << GraphQL::Analysis::AST::MaxQueryDepth
            end
            if max_complexity
              qa << GraphQL::Analysis::AST::MaxQueryComplexity
            end
          else
            if max_depth
              qa << GraphQL::Analysis::MaxQueryDepth.new(max_depth)
            end
            if max_complexity
              qa << GraphQL::Analysis::MaxQueryComplexity.new(max_complexity)
            end
          end

          qa
        else
          qa
        end
      end
    end
  end
end
