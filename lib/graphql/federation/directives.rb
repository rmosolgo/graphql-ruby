# frozen_string_literal: true

module GraphQL
  module Federation
    module Directives
      class Key < GraphQL::Schema::Directive
        graphql_name "key"
        description "Identifies an entity key used to resolve this type across subgraphs."
        locations(OBJECT, INTERFACE)
        repeatable true

        argument :fields, GraphQL::Federation::FieldSet, required: true
        argument :resolvable, Boolean, required: false, default_value: true
      end

      class External < GraphQL::Schema::Directive
        graphql_name "external"
        description "Marks a field or type as owned by another subgraph."
        locations(FIELD_DEFINITION, OBJECT)
      end

      class Requires < GraphQL::Schema::Directive
        graphql_name "requires"
        description "Declares external fields required to resolve this field."
        locations(FIELD_DEFINITION)

        argument :fields, GraphQL::Federation::FieldSet, required: true
      end

      class Provides < GraphQL::Schema::Directive
        graphql_name "provides"
        description "Declares fields this subgraph can provide for the returned entity."
        locations(FIELD_DEFINITION)

        argument :fields, GraphQL::Federation::FieldSet, required: true
      end

      class Extends < GraphQL::Schema::Directive
        graphql_name "extends"
        description "Marks this type as an extension of a type owned by another subgraph."
        locations(OBJECT, INTERFACE)
      end

      class Shareable < GraphQL::Schema::Directive
        graphql_name "shareable"
        description "Marks a field or type as safely resolvable by multiple subgraphs."
        locations(FIELD_DEFINITION, OBJECT)
        repeatable true
      end

      class Inaccessible < GraphQL::Schema::Directive
        graphql_name "inaccessible"
        description "Omits this schema member from the composed API schema."
        locations(
          FIELD_DEFINITION,
          OBJECT,
          INTERFACE,
          UNION,
          ARGUMENT_DEFINITION,
          SCALAR,
          ENUM,
          ENUM_VALUE,
          INPUT_OBJECT,
          INPUT_FIELD_DEFINITION
        )
      end

      class Override < GraphQL::Schema::Directive
        graphql_name "override"
        description "Marks this field as overriding another subgraph's field."
        locations(FIELD_DEFINITION)

        argument :from, String, required: true
        argument :label, String, required: false
      end

      class Tag < GraphQL::Schema::Directive
        graphql_name "tag"
        description "Applies a user-defined label to a schema member."
        locations(
          SCHEMA,
          FIELD_DEFINITION,
          OBJECT,
          INTERFACE,
          UNION,
          ARGUMENT_DEFINITION,
          SCALAR,
          ENUM,
          ENUM_VALUE,
          INPUT_OBJECT,
          INPUT_FIELD_DEFINITION
        )
        repeatable true

        argument :name, String, required: true
      end

      class InterfaceObject < GraphQL::Schema::Directive
        graphql_name "interfaceObject"
        description "Marks an object as providing fields for every entity that implements an interface."
        locations(OBJECT)
      end

      ALL = [
        Key,
        External,
        Requires,
        Provides,
        Extends,
        Shareable,
        Inaccessible,
        Override,
        Tag,
        InterfaceObject,
      ].freeze
    end
  end
end
