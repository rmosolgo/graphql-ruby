# frozen_string_literal: true
# typed: strict
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class OneOf < GraphQL::Schema::Directive
        description "Requires that exactly one field must be supplied and that field must not be `null`."
        locations(GraphQL::Schema::Directive::INPUT_OBJECT)
        default_directive true

        #: (singleton(GraphQL::Schema::InputObject) owner, **untyped arguments) -> void
        def initialize(owner, **arguments)
          super

          owner.extend(IsOneOf)
        end

        module IsOneOf
          #: -> bool
          def one_of?
            true
          end
        end
      end
    end
  end
end
