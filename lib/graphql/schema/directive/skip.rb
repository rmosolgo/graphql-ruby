# frozen_string_literal: true
# typed: strict
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class Skip < Schema::Directive
        description "Directs the executor to skip this field or fragment when the `if` argument is true."

        locations(
          GraphQL::Schema::Directive::FIELD,
          GraphQL::Schema::Directive::FRAGMENT_SPREAD,
          GraphQL::Schema::Directive::INLINE_FRAGMENT
        )

        argument :if, Boolean,
          description: "Skipped when true."

        default_directive true

        #: (Hash[Symbol, untyped] args, GraphQL::Query::Context ctx) -> bool
        def self.static_include?(args, ctx)
          !args[:if]
        end
      end
    end
  end
end
