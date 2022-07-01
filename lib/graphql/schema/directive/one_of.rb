# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class OneOf < GraphQL::Schema::Directive
        description "Indicates an Input Object is a OneOf Input Object."

        locations(
          GraphQL::Schema::Directive::INPUT_OBJECT
        )

        default_directive true
      end
    end
  end
end
