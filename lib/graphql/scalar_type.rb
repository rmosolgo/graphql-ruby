# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class ScalarType < GraphQL::BaseType
    extend Define::InstanceDefinable::DeprecatedDefine

    accepts_definitions :coerce, :coerce_input, :coerce_result
    ensure_defined :coerce_non_null_input, :coerce_result

    module NoOpCoerce
      def self.call(val, ctx)
        val
      end
    end

    def initialize
      super
      self.coerce = NoOpCoerce
    end

    def coerce=(proc)
      self.coerce_input = proc
      self.coerce_result = proc
    end

    def coerce_input=(coerce_input_fn)
      if !coerce_input_fn.nil?
        @coerce_input_proc = ensure_two_arg(coerce_input_fn, :coerce_input)
      end
    end

    def coerce_result(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("coerce_isolated_result")
        ctx = GraphQL::Query::NullContext
      end
      @coerce_result_proc.call(value, ctx)
    end

    def coerce_result=(coerce_result_fn)
      if !coerce_result_fn.nil?
        @coerce_result_proc = ensure_two_arg(coerce_result_fn, :coerce_result)
      end
    end

    def kind
      GraphQL::TypeKinds::SCALAR
    end

    private

    def ensure_two_arg(callable, method_name)
      GraphQL::BackwardsCompatibility.wrap_arity(callable, from: 1, to: 2, name: "#{name}.#{method_name}(val, ctx)")
    end

    def coerce_non_null_input(value, ctx)
      @coerce_input_proc.call(raw_coercion_input(value), ctx)
    end

    def raw_coercion_input(value)
      if value.is_a?(GraphQL::Language::Nodes::InputObject)
        value.to_h
      elsif value.is_a?(Array)
        value.map { |element| raw_coercion_input(element) }
      else
        value
      end
    end

    def validate_non_null_input(value, ctx)
      result = Query::InputValidationResult.new

      coerced_result = begin
        coerce_non_null_input(value, ctx)
      rescue GraphQL::CoercionError => err
        err
      end

      if value.is_a?(GraphQL::Language::Nodes::Enum) || coerced_result.nil?
        result.add_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{name}")
      elsif coerced_result.is_a?(GraphQL::CoercionError)
        result.add_problem(
          coerced_result.message,
          message: coerced_result.message,
          extensions: coerced_result.extensions
        )
      end
      result
    end
  end
end
