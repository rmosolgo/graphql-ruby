# frozen_string_literal: true

module GraphQL
  class Schema
    # Subclasses of this can influence how {GraphQL::Execution::Interpreter} runs queries.
    #
    # - {.include?}: if it returns `false`, the field or fragment will be skipped altogether, as if it were absent
    # - {.resolve}: Wraps field resolution (so it should call `yield` to continue)
    class Directive < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasArguments
      class << self
        def default_graphql_name
          super.downcase
        end

        def locations(*new_locations)
          if new_locations.any?
            @locations = new_locations
          else
            @locations ||= (superclass.respond_to?(:locations) ? superclass.locations : [])
          end
        end

        def default_directive(new_default_directive = nil)
          if new_default_directive != nil
            @default_directive = new_default_directive
          elsif @default_directive.nil?
            @default_directive = (superclass.respond_to?(:default_directive) ? superclass.default_directive : false)
          else
            @default_directive
          end
        end

        def to_graphql
          defn = GraphQL::Directive.new
          defn.name = self.graphql_name
          defn.description = self.description
          defn.locations = self.locations
          defn.default_directive = self.default_directive
          defn.metadata[:type_class] = self
          arguments.each do |name, arg_defn|
            arg_graphql = arg_defn.to_graphql
            defn.arguments[arg_graphql.name] = arg_graphql
          end
          defn
        end

        # If false, this part of the query won't be evaluated
        def include?(_object, _arguments, _context)
          true
        end

        # Continuing is passed as a block; `yield` to continue
        def resolve(object, arguments, context)
          yield
        end
      end

      LOCATIONS = [
        QUERY =                  :QUERY,
        MUTATION =               :MUTATION,
        SUBSCRIPTION =           :SUBSCRIPTION,
        FIELD =                  :FIELD,
        FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
        FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
        INLINE_FRAGMENT =        :INLINE_FRAGMENT,
        SCHEMA =                 :SCHEMA,
        SCALAR =                 :SCALAR,
        OBJECT =                 :OBJECT,
        FIELD_DEFINITION =       :FIELD_DEFINITION,
        ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
        INTERFACE =              :INTERFACE,
        UNION =                  :UNION,
        ENUM =                   :ENUM,
        ENUM_VALUE =             :ENUM_VALUE,
        INPUT_OBJECT =           :INPUT_OBJECT,
        INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
      ]

      DEFAULT_DEPRECATION_REASON = 'No longer supported'
      LOCATION_DESCRIPTIONS = {
        QUERY:                    'Location adjacent to a query operation.',
        MUTATION:                 'Location adjacent to a mutation operation.',
        SUBSCRIPTION:             'Location adjacent to a subscription operation.',
        FIELD:                    'Location adjacent to a field.',
        FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
        FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
        INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
        SCHEMA:                   'Location adjacent to a schema definition.',
        SCALAR:                   'Location adjacent to a scalar definition.',
        OBJECT:                   'Location adjacent to an object type definition.',
        FIELD_DEFINITION:         'Location adjacent to a field definition.',
        ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
        INTERFACE:                'Location adjacent to an interface definition.',
        UNION:                    'Location adjacent to a union definition.',
        ENUM:                     'Location adjacent to an enum definition.',
        ENUM_VALUE:               'Location adjacent to an enum value definition.',
        INPUT_OBJECT:             'Location adjacent to an input object type definition.',
        INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
      }
    end
  end
end
