module GraphQL
  class Schema
    # This module provides a function for validating GraphQL types.
    #
    # Its {RULES} contain objects that respond to `#call(type)`. Rules are
    # looked up for given types (by class ancestry), then applied to
    # the object until an error is returned.
    class Validation
      # Lookup the rules for `object` based on its class,
      # Then returns an error message or `nil`
      # @param object [Object] something to be validated
      # @return [String, Nil] error message, if there was one
      def self.validate(object)
        rules = RULES.reduce([]) do |memo, (parent_class, validations)|
          memo + (object.is_a?(parent_class) ? validations : [])
        end
        # Stops after the first error
        rules.reduce(nil) { |memo, rule| memo || rule.call(object) }
      end

      module Rules
        # @param property_name [Symbol] The method to validate
        # @param allowed_classes [Class] Classes which the return value may be an instance of
        # @return [Proc] A proc which will validate the input by calling `property_name` and asserting it is an instance of one of `allowed_classes`
        def self.assert_property(property_name, *allowed_classes)
          allowed_classes_message = allowed_classes.map(&:name).join(" or ")
          ->(obj) {
            property_value = obj.public_send(property_name)
            is_valid_value = allowed_classes.any? { |allowed_class| property_value.is_a?(allowed_class) }
            is_valid_value ? nil : "#{property_name} must return #{allowed_classes_message}, not #{property_value.class.name} (#{property_value.inspect})"
          }
        end

        # @param property_name [Symbol] The method whose return value will be validated
        # @param from_class [Class] The class for keys in the return value
        # @param to_class [Class] The class for values in the return value
        # @return [Proc] A proc to validate that validates the input by calling `property_name` and asserting that the return value is a Hash of `{from_class => to_class}` pairs
        def self.assert_property_mapping(property_name, from_class, to_class)
          ->(obj) {
            property_value = obj.public_send(property_name)
            error_message = nil
            if !property_value.is_a?(Hash)
              "#{property_name} must be a hash of {#{from_class.name} => #{to_class.name}}, not a #{property_value.class.name} (#{property_value.inspect})"
            else
              invalid_key, invalid_value = property_value.find { |key, value| !key.is_a?(from_class) || !value.is_a?(to_class) }
              if invalid_key
                "#{property_name} must map #{from_class} => #{to_class}, not #{invalid_key.class.name} => #{invalid_value.class.name} (#{invalid_key.inspect} => #{invalid_value.inspect})"
              else
                nil # OK
              end
            end
          }
        end

        # @param property_name [Symbol] The method whose return value will be validated
        # @param list_member_class [Class] The class which each member of the returned array should be an instance of
        # @return [Proc] A proc to validate the input by calling `property_name` and asserting that the return is an Array of `list_member_class` instances
        def self.assert_property_list_of(property_name, list_member_class)
          ->(obj) {
            property_value = obj.public_send(property_name)
            if !property_value.is_a?(Array)
              "#{property_name} must be an Array of #{list_member_class.name}, not a #{property_value.class.name} (#{property_value.inspect})"
            else
              invalid_member = property_value.find { |value| !value.is_a?(list_member_class) }
              if invalid_member
                "#{property_name} must contain #{list_member_class.name}, not #{invalid_member.class.name} (#{invalid_member.inspect})"
              else
                nil # OK
              end
            end
          }
        end

        def self.assert_named_items_are_valid(item_name, get_items_proc)
          ->(type) {
            items = get_items_proc.call(type)
            error_message = nil
            items.each do |item|
              item_message = GraphQL::Schema::Validation.validate(item)
              if item_message
                error_message = "#{item_name} #{item.name.inspect} #{item_message}"
                break
              end
            end
            error_message
          }
        end


        FIELDS_ARE_VALID = Rules.assert_named_items_are_valid("field", ->(type) { type.all_fields })

        HAS_ONE_OR_MORE_POSSIBLE_TYPES = ->(type) {
          type.possible_types.length >= 1 ? nil : "must have at least one possible type"
        }

        NAME_IS_STRING = Rules.assert_property(:name, String)
        DESCRIPTION_IS_STRING_OR_NIL = Rules.assert_property(:description, String, NilClass)
        ARGUMENTS_ARE_STRING_TO_ARGUMENT = Rules.assert_property_mapping(:arguments, String, GraphQL::Argument)
        ARGUMENTS_ARE_VALID =  Rules.assert_named_items_are_valid("argument", ->(type) { type.arguments.values })

        DEFAULT_VALUE_IS_VALID_FOR_TYPE = ->(type) {
          if !type.default_value.nil?
            coerced_value = begin
              type.type.coerce_result(type.default_value)
            rescue => ex
              ex
            end

            if coerced_value.nil? || coerced_value.is_a?(StandardError)
              msg = "default value #{type.default_value.inspect} is not valid for type #{type.type}"
              msg += " (#{coerced_value})" if coerced_value.is_a?(StandardError)
              msg
            end
          end
        }

        TYPE_IS_VALID_INPUT_TYPE = ->(type) {
          outer_type = type.type
          inner_type = outer_type.is_a?(GraphQL::BaseType) ? outer_type.unwrap : nil

          case inner_type
          when GraphQL::ScalarType, GraphQL::InputObjectType, GraphQL::EnumType
            # OK
          else
            "type must be a valid input type (Scalar or InputObject), not #{outer_type.class} (#{outer_type})"
          end
        }

        SCHEMA_CAN_RESOLVE_TYPES = ->(schema) {
          if schema.types.values.any? { |type| type.kind.resolves? } && schema.resolve_type_proc.nil?
            "schema contains Interfaces or Unions, so you must define a `resolve_type (obj, ctx) -> { ... }` function"
          else
            # :+1:
          end
        }

        SCHEMA_CAN_FETCH_IDS = ->(schema) {
          has_node_field = schema.query && schema.query.all_fields.any? { |f| f.metadata[:relay_node_field] }
          if has_node_field && schema.object_from_id_proc.nil?
            "schema contains `node(id:...)` field, so you must define a `object_from_id (id, ctx) -> { ... }` function"
          else
            # :rocket:
          end
        }

        SCHEMA_CAN_GENERATE_IDS = ->(schema) {
          has_id_field = schema.types.values.any? { |t| t.kind.fields? && t.all_fields.any? { |f| f.resolve_proc.is_a?(GraphQL::Relay::GlobalIdResolve) } }
          if has_id_field && schema.id_from_object_proc.nil?
            "schema contains `global_id_field`, so you must define a `id_from_object (obj, type, ctx) -> { ... }` function"
          else
            # :ok_hand:
          end
        }
      end

      # A mapping of `{Class => [Proc, Proc...]}` pairs.
      # To validate an instance, find entries where `object.is_a?(key)` is true.
      # Then apply each rule from the matching values.
      RULES = {
        GraphQL::Field => [
          Rules::NAME_IS_STRING,
          Rules::DESCRIPTION_IS_STRING_OR_NIL,
          Rules.assert_property(:deprecation_reason, String, NilClass),
          Rules.assert_property(:type, GraphQL::BaseType),
          Rules.assert_property(:property, Symbol, NilClass),
          Rules::ARGUMENTS_ARE_STRING_TO_ARGUMENT,
          Rules::ARGUMENTS_ARE_VALID,
        ],
        GraphQL::Argument => [
          Rules::NAME_IS_STRING,
          Rules::DESCRIPTION_IS_STRING_OR_NIL,
          Rules::TYPE_IS_VALID_INPUT_TYPE,
          Rules::DEFAULT_VALUE_IS_VALID_FOR_TYPE,
        ],
        GraphQL::BaseType => [
          Rules::NAME_IS_STRING,
          Rules::DESCRIPTION_IS_STRING_OR_NIL,
        ],
        GraphQL::ObjectType => [
          Rules.assert_property_list_of(:interfaces, GraphQL::InterfaceType),
          Rules::FIELDS_ARE_VALID,
        ],
        GraphQL::InputObjectType => [
          Rules::ARGUMENTS_ARE_STRING_TO_ARGUMENT,
          Rules::ARGUMENTS_ARE_VALID,
        ],
        GraphQL::UnionType => [
          Rules.assert_property_list_of(:possible_types, GraphQL::ObjectType),
          Rules::HAS_ONE_OR_MORE_POSSIBLE_TYPES,
        ],
        GraphQL::InterfaceType => [
          Rules::FIELDS_ARE_VALID,
        ],
        GraphQL::Schema => [
          Rules::SCHEMA_CAN_RESOLVE_TYPES,
          Rules::SCHEMA_CAN_FETCH_IDS,
          Rules::SCHEMA_CAN_GENERATE_IDS,
        ],
      }
    end
  end
end
