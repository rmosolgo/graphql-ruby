# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class Schema
    class Scalar < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::ValidatesInput

      class << self
        #: (untyped val, GraphQL::Query::Context ctx) -> untyped
        def coerce_input(val, ctx)
          val
        end

        #: (untyped val, GraphQL::Query::Context ctx) -> untyped
        def coerce_result(val, ctx)
          val
        end

        #: -> GraphQL::TypeKinds::TypeKind
        def kind
          GraphQL::TypeKinds::SCALAR
        end

        #: (?String? new_url) -> String?
        def specified_by_url(new_url = nil)
          if new_url
            directive(GraphQL::Schema::Directive::SpecifiedBy, url: new_url)
          elsif (directive = directives.find { |dir| dir.graphql_name == "specifiedBy" })
            directive.arguments[:url] # rubocop:disable Development/ContextIsPassedCop
          elsif superclass.respond_to?(:specified_by_url)
            superclass.specified_by_url
          else
            nil
          end
        end

        #: (?bool? is_default) -> bool?
        def default_scalar(is_default = nil)
          if !is_default.nil?
            @default_scalar = is_default #: bool?
          end
          @default_scalar
        end

        #: -> bool
        def default_scalar?
          @default_scalar ||= false
        end

        #: (untyped value, GraphQL::Query::Context ctx, ?max_errors: Integer?) -> GraphQL::Query::InputValidationResult?
        def validate_non_null_input(value, ctx, max_errors: nil)
          coerced_result = begin
            coerce_input(value, ctx)
          rescue GraphQL::CoercionError => err
            err
          rescue StandardError => err
            ctx.query.handle_or_reraise(err)
          end

          if coerced_result.nil?
            Query::InputValidationResult.from_problem("Could not coerce value #{GraphQL::Language.serialize(value)} to #{graphql_name}")
          elsif coerced_result.is_a?(GraphQL::CoercionError)
            Query::InputValidationResult.from_problem(coerced_result.message, message: coerced_result.message, extensions: coerced_result.extensions)
          else
            nil
          end
        end
      end
    end
  end
end
