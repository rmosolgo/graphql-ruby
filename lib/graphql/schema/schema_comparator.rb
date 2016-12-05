module GraphQL
  class Schema
    module SchemaComparator
      class << self
        def find_changes(old_schema, new_schema)
          SchemaComparator.find_changes(old_schema, new_schema)
        end
      end

      module SchemaComparator
        extend self

        def find_changes(old_schema, new_schema)
          old_types = old_schema.types.values.map(&:name)
          new_types = new_schema.types.values.map(&:name)

          removed_types = (old_types - new_types).map{ |type| type_removed(type) }
          added_types = (new_types - old_types).map{ |type| type_added(type) }

          changed = (old_types & new_types).map{ |type|
            old_type = old_schema.types[type]
            new_type = new_schema.types[type]

            if old_type.class == new_type.class
              find_changes_in_types(old_type, new_type)
            else
              type_kind_changed(old_type, new_type)
            end
          }.flatten

          removed_types + added_types + changed +
            find_changes_in_schema(old_schema, new_schema) +
            find_changes_in_directives(old_schema, new_schema)
        end

        def find_changes_in_types(old_type, new_type)
          changes = []

          if old_type.class == new_type.class
            case old_type
            when EnumType
              changes.push(*find_changes_in_enum_types(old_type, new_type))
            when UnionType
              changes.push(*find_changes_in_union_type(old_type, new_type))
            when InputObjectType
              changes.push(*find_changes_in_input_object_type(old_type, new_type))
            when ObjectType
              changes.push(*find_changes_in_object_type(old_type, new_type))
            when InterfaceType
              changes.push(*find_changes_in_interface_type(old_type, new_type))
            end
          end

          if old_type.description != new_type.description
            changes.push(type_description_changed(new_type))
          end

          changes
        end

        def find_changes_in_schema(old_schema, new_schema)
          changes = []

          changes << schema_query_type_changed(old_schema.query, new_schema.query) if old_schema.query.name != new_schema.query.name
          changes << schema_mutation_type_changed(old_schema.mutation, new_schema.mutation, !old_schema.mutation.nil?) if old_schema.mutation.try(:name) != new_schema.mutation.try(:name)
          changes << schema_subscription_type_changed(old_schema.subscription, new_schema.subscription, !old_schema.subscription.nil?) if old_schema.subscription.try(:name) != new_schema.subscription.try(:name)

          changes
        end

        def find_changes_in_directives(old_schema, new_schema)
          old_directives = old_schema.directives.values.map(&:name)
          new_directives = new_schema.directives.values.map(&:name)

          removed = (old_directives - new_directives).map{ |directive| directive_removed(old_schema.directives[directive]) }

          added = (new_directives - old_directives).map{ |directive| directive_added(new_schema.directives[directive]) }

          changed = (old_directives & new_directives).map{ |directive|
            changes = []

            old_directive = old_schema.directives[directive]
            new_directive = new_schema.directives[directive]

            changes << directive_description_changed(new_directive) if old_directive.description != new_directive.description
            changes.push(*find_changes_in_directive(old_directive, new_directive))

            changes
          }.flatten

          removed + added + changed
        end

        def find_changes_in_directive(old_directive, new_directive)
          location_changes = find_changes_in_directive_locations(old_directive, new_directive)

          field_changes = find_changes_in_arguments(
            old_directive.arguments,
            new_directive.arguments,
            removed_method: lambda { |argument| directive_argument_removed(new_directive, argument) },
            added_method: lambda { |argument, breaking_change| directive_argument_added(new_directive, argument, breaking_change) },
            description_method: lambda { |argument| directive_argument_description_changed(new_directive, argument) },
            default_method: lambda { |argument, old_default_value, new_default_value| directive_argument_default_changed(new_directive, argument, old_default_value, new_default_value) },
            type_change_method: lambda { |argument, old_argument_type, new_argument_type, breaking_change| directive_argument_type_changed(new_directive, argument, old_argument_type, new_argument_type, breaking_change) },
          )

          location_changes + field_changes
        end

        def find_changes_in_directive_locations(old_directive, new_directive)
          old_locations = old_directive.locations
          new_locations = new_directive.locations

          removed = (old_locations - new_locations).map{ |location| directive_location_removed(new_directive, location) }

          added = (new_locations - old_locations).map{ |location| directive_location_added(new_directive, location) }

          removed + added
        end

        def find_changes_in_arguments(old_arguments, new_arguments, removed_method:, added_method:, description_method:, default_method:, type_change_method:)
          old = old_arguments.values.map(&:name)
          new = new_arguments.values.map(&:name)

          removed = (old - new).map{ |argument| removed_method.call(old_arguments[argument]) }

          added = (new - old).map{ |argument|
            added_method.call(new_arguments[argument], required?(new_arguments[argument].type))
          }

          changed = (old & new).map{ |argument|
            old_argument = old_arguments[argument]
            new_argument = new_arguments[argument]

            changes = []

            changes << description_method.call(new_argument) if old_argument.description != new_argument.description
            changes.push(*find_changes_in_argument(old_argument, new_argument, default_method: default_method, type_change_method: type_change_method))

            changes
          }.flatten

          removed + added + changed
        end

        def find_changes_in_argument(old_argument, new_argument, default_method:, type_change_method:)
          old_default_value = old_argument.default_value
          new_default_value = new_argument.default_value

          old_argument_type = old_argument.type.to_s
          new_argument_type = new_argument.type.to_s

          changes = []

          if old_argument_type != new_argument_type
            breaking_change = if required?(old_argument.type) && old_argument.type.unwrap == new_argument.type
              false
            else
              true
            end

            changes << type_change_method.call(new_argument, old_argument_type, new_argument_type, breaking_change)
          end

          if old_default_value != new_default_value
            changes << default_method.call(new_argument, old_default_value, new_default_value)
          end

          changes
        end

        def find_changes_in_enum_types(old_type, new_type)
          old_values = old_type.values.keys
          new_values = new_type.values.keys

          removed = (old_values - new_values).map{ |value| enum_value_removed(new_type, value) }

          added = (new_values - old_values).map{ |value| enum_value_added(new_type, value) }

          changed = (old_values & new_values).map{ |value|
            old_value = old_type.values[value]
            new_value = new_type.values[value]

            changes = []

            changes << enum_value_description_changed(new_type, value) if old_value.description != new_value.description
            # TODO should differentiate new deprecations from deprecation reason being changed
            changes << enum_value_deprecated(new_type, value) if old_value.deprecation_reason != new_value.deprecation_reason

            changes
          }.flatten

          removed + added + changed
        end

        def find_changes_in_union_type(old_type, new_type)
          old_types = old_type.possible_types.map(&:name)
          new_types = new_type.possible_types.map(&:name)

          removed = (old_types - new_types).map{ |removed_member_type| union_member_removed(new_type, removed_member_type) }

          added = (new_types - old_types).map{ |new_member_type| union_member_added(new_type, new_member_type) }

          removed + added
        end

        def find_changes_in_input_object_type(old_type, new_type)
          old_fields = old_type.arguments.values.map(&:name)
          new_fields = new_type.arguments.values.map(&:name)

          removed = (old_fields - new_fields).map{ |field| input_field_removed(new_type, old_type.arguments[field]) }

          added = (new_fields - old_fields).map{ |field|
            input_field_added(new_type, new_type.arguments[field], required?(new_type.arguments[field].type))
          }

          changed = (old_fields & new_fields).map{ |field|
            old_field = old_type.arguments[field]
            new_field = new_type.arguments[field]

            changes = []

            changes << input_field_description_changed(new_type, new_field) if old_field.description != new_field.description
            changes << find_changes_in_input_fields(old_type, new_type, old_field, new_field)

            changes
          }.flatten

          removed + added + changed
        end

        def find_changes_in_input_fields(old_type, new_type, old_field, new_field)
          old_default_value = old_field.default_value
          new_default_value = new_field.default_value

          changes = []

          if old_default_value != new_default_value
            changes << input_field_default_changed(new_type, new_field, old_default_value, new_default_value)
          end

          old_field_type = old_field.type
          new_field_type = new_field.type

          if old_field_type.to_s != new_field_type.to_s
            breaking_change = if required?(old_field_type) && old_field_type.unwrap == new_field_type
              false
            else
              true
            end

            changes << input_field_type_changed(new_type, new_field, old_field_type, new_field_type, breaking_change)
          end

          changes
        end

        def find_changes_in_object_type(old_type, new_type)
          interface_changes = find_changes_in_object_type_interfaces(old_type, new_type)

          field_changes = find_changes_in_object_type_fields(old_type, new_type)

          interface_changes + field_changes
        end

        def find_changes_in_object_type_interfaces(old_type, new_type)
          old_interfaces = old_type.interfaces.map(&:name)
          new_interfaces = new_type.interfaces.map(&:name)

          removed = (old_interfaces - new_interfaces).map{ |interface| object_type_interface_removed(new_type, interface) }

          added = (new_interfaces - old_interfaces).map{ |interface| object_type_interface_added(new_type, interface) }

          removed + added
        end

        def find_changes_in_object_type_fields(old_type, new_type)
          old_fields = old_type.fields.values.map(&:name)
          new_fields = new_type.fields.values.map(&:name)

          removed = (old_fields - new_fields).map{ |field| field_removed(new_type, old_type.fields[field]) }

          added = (new_fields - old_fields).map{ |field| field_added(new_type, new_type.fields[field]) }

          changed = (old_fields & new_fields).map { |field|
            old_field = old_type.fields[field]
            new_field = new_type.fields[field]

            changes = find_changes_in_fields(old_type, new_type, old_field, new_field)

            # TODO Description changed
            # TODO Deprecation changed
            # TODO should differentiate new deprecations from deprecation reason being changed
            # TODO Find in fields

            changes
          }.flatten

          removed + added + changed
        end

        def find_changes_in_fields(old_type, new_type, old_field, new_field)
          old_field_type = old_field.type.to_s
          new_field_type = new_field.type.to_s

          type_change = []
          # changes << field_type_changed(

          argument_changes = find_changes_in_arguments(
            old_field.arguments,
            new_field.arguments,
            removed_method: lambda { |argument| nil }, # TODO
            added_method: lambda { |argument, breaking_change| object_type_argument_added(new_type, new_field, argument, breaking_change) },
            description_method: lambda { |argument| object_type_argument_description_changed(new_type, new_field, argument) }, # TODO
            default_method: lambda { |argument, old_default_value, new_default_value| object_type_argument_default_changed(new_type, new_field, argument, old_default_value, new_default_value) },
            type_change_method: lambda { |argument, old_argument_type, new_argument_type, breaking_change| object_type_argument_type_changed(new_type, new_field, argument, old_argument_type, new_argument_type, breaking_change) },
          )

          type_change + argument_changes
        end

        def find_changes_in_interface_type(old_type, new_type)
          find_changes_in_object_type_fields(old_type, new_type)
        end

        def type_removed(type)
          {
            type: GraphQL::Schema::SchemaComparatorChange::TYPE_REMOVED,
            description: "`#{type}` type was removed",
            breaking_change: true,
          }
        end

        def type_added(type)
          {
            type: GraphQL::Schema::SchemaComparatorChange::TYPE_ADDED,
            description: "`#{type}` type was added",
            breaking_change: false,
          }
        end

        def type_kind_changed(old_type, new_type)
          {
            type: GraphQL::Schema::SchemaComparatorChange::TYPE_KIND_CHANGED,
            description: "`#{old_type.name}` changed from an #{kind(old_type)} type to a #{kind(new_type)} type",
            breaking_change: true,
          }
        end

        def type_description_changed(type)
          {
            type: GraphQL::Schema::SchemaComparatorChange::TYPE_DESCRIPTION_CHANGED,
            description: "`#{type.name}` type description is changed",
            breaking_change: false,
          }
        end

        def enum_value_added(enum_type, value)
          {
            type: GraphQL::Schema::SchemaComparatorChange::ENUM_VALUE_ADDED,
            description: "Enum value `#{value}` was added to enum `#{enum_type.name}`",
            breaking_change: false,
          }
        end

        def enum_value_removed(enum_type, value)
          {
            type: GraphQL::Schema::SchemaComparatorChange::ENUM_VALUE_REMOVED,
            description: "Enum value `#{value}` was removed from enum `#{enum_type.name}`",
            breaking_change: true,
          }
        end

        def enum_value_description_changed(enum_type, value)
          {
            type: GraphQL::Schema::SchemaComparatorChange::ENUM_VALUE_DESCRIPTION_CHANGED,
            description: "`#{enum_type.name}.#{value}` description changed",
            breaking_change: false,
          }
        end

        def enum_value_deprecated(enum_type, value)
          {
            type: GraphQL::Schema::SchemaComparatorChange::ENUM_VALUE_DEPRECATED,
            description: "Enum value `#{value}` was deprecated in enum `#{enum_type.name}`",
            breaking_change: false,
          }
        end

        def union_member_removed(union_type, type_name)
          {
            type: GraphQL::Schema::SchemaComparatorChange::UNION_MEMBER_REMOVED,
            description: "`#{type_name}` type was removed from union `#{union_type.name}`",
            breaking_change: true,
          }
        end

        def union_member_added(union_type, type_name)
          {
            type: GraphQL::Schema::SchemaComparatorChange::UNION_MEMBER_ADDED,
            description: "`#{type_name}` type was added to union `#{union_type.name}`",
            breaking_change: false,
          }
        end

        def directive_added(directive)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ADDED,
            description: "`#{directive.name}` directive was added",
            breaking_change: false,
          }
        end

        def directive_removed(directive)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_REMOVED,
            description: "`#{directive.name}` directive was removed",
            breaking_change: true,
          }
        end

        def directive_description_changed(directive)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_DESCRIPTION_CHANGED,
            description: "`#{directive.name}` directive description is changed",
            breaking_change: false,
          }
        end

        def directive_argument_removed(directive, argument)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ARGUMENT_REMOVED,
            description: "Argument `#{argument.name}` was removed from `#{directive.name}` directive",
            breaking_change: true,
          }
        end

        def directive_argument_added(directive, argument, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ARGUMENT_ADDED,
            description: "Argument `#{argument.name}` was added to `#{directive.name}` directive",
            breaking_change: breaking_change,
          }
        end

        def directive_argument_description_changed(directive, argument)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ARGUMENT_DESCRIPTION_CHANGED,
            description: "`#{directive.name}(#{argument.name})` description is changed",
            breaking_change: false,
          }
        end

        def directive_argument_default_changed(directive, argument, old_default_value, new_default_value)
          old_default_value = old_default_value ? "`#{JSON.dump(old_default_value)}`" : 'none'
          new_default_value = new_default_value ? "`#{JSON.dump(new_default_value)}`" : 'none'

          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ARGUMENT_DEFAULT_CHANGED,
            description: "`#{directive.name}(#{argument.name})` default value changed from #{old_default_value} to #{new_default_value}",
            breaking_change: false,
          }
        end

        def directive_argument_type_changed(directive, argument, old_type, new_type, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_ARGUMENT_TYPE_CHANGED,
            description: "`#{directive.name}(#{argument.name})` type changed from `#{old_type}` to `#{new_type}`",
            breaking_change: breaking_change,
          }
        end

        def directive_location_added(directive, location)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_LOCATION_ADDED,
            description: "`#{directive_location(location)}` directive location added to `#{directive.name}` directive",
            breaking_change: false,
          }
        end

        def directive_location_removed(directive, location)
          {
            type: GraphQL::Schema::SchemaComparatorChange::DIRECTIVE_LOCATION_REMOVED,
            description: "`#{directive_location(location)}` directive location removed from `#{directive.name}` directive",
            breaking_change: true,
          }
        end

        def input_field_removed(type, input_field)
          {
            type: GraphQL::Schema::SchemaComparatorChange::INPUT_FIELD_REMOVED,
            description: "Input field `#{input_field.name}` was removed from `#{type.name}` type",
            breaking_change: true,
          }
        end

        def input_field_added(type, input_field, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::INPUT_FIELD_ADDED,
            description: "Input field `#{input_field.name}` was added to `#{type.name}` type",
            breaking_change: breaking_change,
          }
        end

        def input_field_description_changed(type, input_field)
          {
            type: GraphQL::Schema::SchemaComparatorChange::INPUT_FIELD_DESCRIPTION_CHANGED,
            description: "`#{type.name}.#{input_field.name}` description is changed",
            breaking_change: false,
          }
        end

        def input_field_default_changed(type, field, old_default_value, new_default_value)
          old_default_value = old_default_value ? "`#{JSON.dump(old_default_value)}`" : 'none'
          new_default_value = new_default_value ? "`#{JSON.dump(new_default_value)}`" : 'none'

          {
            type: GraphQL::Schema::SchemaComparatorChange::INPUT_FIELD_DEFAULT_CHANGED,
            description: "`#{type.name}.#{field.name}` default value changed from #{old_default_value} to #{new_default_value}",
            breaking_change: false,
          }
        end

        def input_field_type_changed(type, field, old_type, new_type, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::INPUT_FIELD_TYPE_CHANGED,
            description: "`#{type.name}.#{field.name}` input field type changed from `#{old_type}` to `#{new_type}`",
            breaking_change: breaking_change,
          }
        end

        def object_type_interface_added(type, interface_name)
          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_INTERFACE_ADDED,
            description: "`#{type.name}` object type now implements `#{interface_name}` interface",
            breaking_change: false,
          }
        end

        def object_type_interface_removed(type, interface_name)
          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_INTERFACE_REMOVED,
            description: "`#{type.name}` object type no longer implements `#{interface_name}` interface",
            breaking_change: true,
          }
        end

        def object_type_argument_type_changed(type, field, argument, old_type, new_type, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_ARGUMENT_TYPE_CHANGED,
            description: "`#{type.name}.#{field.name}(#{argument.name})` type changed from `#{old_type}` to `#{new_type}`",
            breaking_change: breaking_change,
          }
        end

        def object_type_argument_added(type, field, argument, breaking_change)
          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_ARGUMENT_ADDED,
            description: "Argument `#{argument.name}` was added to `#{type.name}.#{field.name}` field",
            breaking_change: breaking_change,
          }
        end

        def object_type_argument_default_changed(type, field, argument, old_default_value, new_default_value)
          old_default_value = old_default_value ? "`#{JSON.dump(old_default_value)}`" : 'none'
          new_default_value = new_default_value ? "`#{JSON.dump(new_default_value)}`" : 'none'

          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_ARGUMENT_DEFAULT_CHANGED,
            description: "`#{type.name}.#{field.name}(#{argument.name})` default value changed from #{old_default_value} to #{new_default_value}",
            breaking_change: false,
          }
        end

        def object_type_argument_description_changed(type, field, argument)
          {
            type: GraphQL::Schema::SchemaComparatorChange::OBJECT_TYPE_ARGUMENT_DESCRIPTION_CHANGED,
            description: "`#{type.name}.#{field.name}(#{argument.name})` description was changed",
            breaking_change: false,
          }
        end

        def field_removed(type, field)
          {
            type: GraphQL::Schema::SchemaComparatorChange::FIELD_REMOVED,
            description: "Field `#{field.name}` was removed from `#{type.name}` type",
            breaking_change: true,
          }
        end

        def field_added(type, field)
          {
            type: GraphQL::Schema::SchemaComparatorChange::FIELD_ADDED,
            description: "Field `#{field.name}` was added to `#{type.name}` type",
            breaking_change: false,
          }
        end

        def schema_query_type_changed(old_type, new_type)
          {
            type: GraphQL::Schema::SchemaComparatorChange::SCHEMA_QUERY_TYPE_CHANGED,
            description: "Schema query type changed from `#{old_type.name}` to `#{new_type.name}` type",
            breaking_change: false,
          }
        end

        def schema_mutation_type_changed(old_type, new_type, breaking_change)
          old_name = old_type ? "`#{old_type.name}`" : 'none'
          new_name = new_type ? "`#{new_type.name}`" : 'none'

          {
            type: GraphQL::Schema::SchemaComparatorChange::SCHEMA_MUTATION_TYPE_CHANGED,
            description: "Schema mutation type changed from #{old_name} to #{new_name} type",
            breaking_change: breaking_change,
          }
        end

        def schema_subscription_type_changed(old_type, new_type, breaking_change)
          old_name = old_type ? "`#{old_type.name}`" : 'none'
          new_name = new_type ? "`#{new_type.name}`" : 'none'

          {
            type: GraphQL::Schema::SchemaComparatorChange::SCHEMA_SUBSCRIPTION_TYPE_CHANGED,
            description: "Schema subscription type changed from #{old_name} to #{new_name} type",
            breaking_change: breaking_change,
          }
        end

        def directive_location(location)
          location.to_s.split('_').collect(&:capitalize).join
        end

        def required?(type)
          type.is_a?(NonNullType)
        end

        def optional?(type)
          !required?(type)
        end

        def kind(type)
          case type
          when ObjectType
            'Object'
          when InterfaceType
            'Interface'
          when ScalarType
            'Scalar'
          when UnionType
            'Union'
          when EnumType
            'Enum'
          when InputObjectType
            'InputObject'
          else
            raise "Unsupported type kind: #{type.class}"
          end
        end
      end

      private_constant :SchemaComparator
    end
  end
end
