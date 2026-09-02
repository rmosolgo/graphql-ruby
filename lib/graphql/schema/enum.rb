# frozen_string_literal: true

module GraphQL
  class Schema
    # Extend this class to define GraphQL enums in your schema.
    #
    # By default, GraphQL enum values are translated into Ruby strings.
    # You can provide a custom value with the `value:` keyword.
    #
    # **Examples**
    #
    # **Example: # equivalent to**
    #
    # ```ruby
    # # enum PizzaTopping {
    # #   MUSHROOMS
    # #   ONIONS
    # #   PEPPERS
    # # }
    # class PizzaTopping < GraphQL::Schema::Enum
    #   value :MUSHROOMS
    #   value :ONIONS
    #   value :PEPPERS
    # end
    # ```
    class Enum < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::ValidatesInput

      # This is raised when either:
      #
      # - A resolver returns a value which doesn't match any of the enum's configured values;
      # - Or, the resolver returns a value which matches a value, but that value's `authorized?` check returns false.
      #
      # In either case, the field should be modified so that the invalid value isn't returned.
      #
      # [GraphQL::Schema::Enum](rdoc-ref:GraphQL::Schema::Enum) subclasses get their own subclass of this error, so that bug trackers can better show where they came from.
      class UnresolvedValueError < GraphQL::Error
        def initialize(value:, enum:, context:, authorized:)
          fix_message = if authorized == false
            ", but this value was unauthorized. Update the field or resolver to return a different value in this case (or return `nil`)."
          else
            ", but this isn't a valid value for `#{enum.graphql_name}`. Update the field or resolver to return one of `#{enum.graphql_name}`'s values instead."
          end
          message = if (cp = context[:current_path]) && (cf = context[:current_field])
            "`#{cf.path}` returned `#{value.inspect}` at `#{cp.join(".")}`#{fix_message}"
          else
            "`#{value.inspect}` was returned for `#{enum.graphql_name}`#{fix_message}"
          end
          super(message)
        end
      end

      # Raised when a [GraphQL::Schema::Enum](rdoc-ref:GraphQL::Schema::Enum) is defined to have no values.
      # This can also happen when all values return false for `.visible?`.
      class MissingValuesError < GraphQL::Error
        def initialize(enum_type)
          @enum_type = enum_type
          super("Enum types require at least one value, but #{enum_type.graphql_name} didn't provide any for this query. Make sure at least one value is defined and visible for this query.")
        end
      end

      class << self
        # Define a value for this enum
        # See [Schema::EnumValue](rdoc-ref:Schema::EnumValue) which handles these inputs by default
        #
        # **Options**
        #
        # - `kwargs.:graphql_name` (`String, Symbol`) — the GraphQL value for this, usually `SCREAMING_CASE`
        # - `kwargs.:description,` (`String`) — the GraphQL description for this value, present in documentation
        # - `kwargs.:comment,` (`String`) — the GraphQL comment for this value, present in documentation
        # - `kwargs.:value` (`::Object`) — the translated Ruby value for this object (defaults to `graphql_name`)
        # - `kwargs.:value_method,` (`::Object`) — the method name to fetch `graphql_name` (defaults to `graphql_name.downcase`)
        # - `kwargs.:deprecation_reason` (`String`) — if this object is deprecated, include a message here
        #
        # **Parameters**
        #
        # - `value_method` (`Symbol, false`) — A method to generate for this value, or `false` to skip generation
        #
        # **Returns**
        #
        # - `void`
        #
        # :call-seq:
        #   value(*args, Symbol | false value_method:, **kwargs, &block) -> void
        def value(*args, value_method: nil, **kwargs, &block)
          kwargs[:owner] = self
          value = enum_value_class.new(*args, **kwargs, &block)

          if value_method || (value_methods && value_method != false)
            generate_value_method(value, value_method)
          end

          key = value.graphql_name
          prev_value = own_values[key]
          case prev_value
          when nil
            own_values[key] = value
          when GraphQL::Schema::EnumValue
            own_values[key] = [prev_value, value]
          when Array
            prev_value << value
          else
            raise "Invariant: Unexpected enum value for #{key.inspect}: #{prev_value.inspect}"
          end
          value
        end

        # **Returns**
        #
        # - `Array<GraphQL::Schema::EnumValue>` — Possible values of this enum
        #
        # :call-seq:
        #   enum_values(context:) -> Array[GraphQL::Schema::EnumValue]
        def enum_values(context = GraphQL::Query::NullContext.instance)
          inherited_values = superclass.respond_to?(:enum_values) ? superclass.enum_values(context) : nil
          visible_values = []
          types = Warden.types_from_context(context)
          own_values.each do |key, values_entry|
            visible_value = nil
            if values_entry.is_a?(Array)
              values_entry.each do |v|
                if types.visible_enum_value?(v, context)
                  if visible_value.nil?
                    visible_value = v
                    visible_values << v
                  else
                    raise DuplicateNamesError.new(
                      duplicated_name: v.path, duplicated_definition_1: visible_value.inspect, duplicated_definition_2: v.inspect
                    )
                  end
                end
              end
            elsif types.visible_enum_value?(values_entry, context)
              visible_values << values_entry
            end
          end

          if inherited_values
            # Local values take precedence over inherited ones
            inherited_values.each do |i_val|
              if !visible_values.any? { |v| v.graphql_name == i_val.graphql_name }
                visible_values << i_val
              end
            end
          end

          visible_values
        end

        # **Returns**
        #
        # - `Array<Schema::EnumValue>` — An unfiltered list of all definitions
        #
        # :call-seq:
        #   all_enum_value_definitions() -> Array[Schema::EnumValue]
        def all_enum_value_definitions
          all_defns = if superclass.respond_to?(:all_enum_value_definitions)
            superclass.all_enum_value_definitions
          else
            []
          end

          @own_values && @own_values.each do |_key, value|
            if value.is_a?(Array)
              all_defns.concat(value)
            else
              all_defns << value
            end
          end

          all_defns
        end

        # **Returns**
        #
        # - `Hash<String => GraphQL::Schema::EnumValue>` — Possible values of this enum, keyed by name.
        #
        # :call-seq:
        #   values(context:) -> Hash[String, GraphQL::Schema::EnumValue]
        def values(context = GraphQL::Query::NullContext.instance)
          enum_values(context).each_with_object({}) { |val, obj| obj[val.graphql_name] = val }
        end

        # **Returns**
        #
        # - `Class` — for handling `value(...)` inputs and building `GraphQL::Enum::EnumValue`s out of them
        #
        # :call-seq:
        #   enum_value_class(new_enum_value_class) -> Class
        def enum_value_class(new_enum_value_class = nil)
          if new_enum_value_class
            @enum_value_class = new_enum_value_class
          elsif defined?(@enum_value_class) && @enum_value_class
            @enum_value_class
          else
            superclass <= GraphQL::Schema::Enum ? superclass.enum_value_class : nil
          end
        end

        def value_methods(new_value = NOT_CONFIGURED)
          if NOT_CONFIGURED.equal?(new_value)
            if @value_methods != nil
              @value_methods
            else
              find_inherited_value(:value_methods, false)
            end
          else
            @value_methods = new_value
          end
        end

        def kind
          GraphQL::TypeKinds::ENUM
        end

        def validate_non_null_input(value_name, ctx, max_errors: nil)
          allowed_values = ctx.types.enum_values(self)
          matching_value = allowed_values.find { |v| v.graphql_name == value_name }

          if matching_value.nil?
            GraphQL::Query::InputValidationResult.from_problem("Expected #{GraphQL::Language.serialize(value_name)} to be one of: #{allowed_values.map(&:graphql_name).join(', ')}")
          else
            nil
          end
        # rescue MissingValuesError
        #   nil
        end

        # Called by the runtime when a field returns a value to give back to the client.
        # This method checks that the incoming [value](rdoc-ref:value) matches one of the enum's defined values.
        #
        # **Parameters**
        #
        # - `value` (`Object`) — Any value matching the values for this enum.
        # - `ctx` (`GraphQL::Query::Context`)
        #
        # **Raises**
        #
        # - `GraphQL::Schema::Enum::UnresolvedValueError` — if [value](rdoc-ref:value) doesn't match a configured value or if the matching value isn't authorized.
        #
        # **Returns**
        #
        # - `String` — The GraphQL-ready string for [value](rdoc-ref:value)
        #
        # :call-seq:
        #   coerce_result(Object value, GraphQL::Query::Context ctx) -> String
        def coerce_result(value, ctx)
          types = ctx.types
          all_values = types ? types.enum_values(self) : values.each_value
          enum_value = all_values.find { |val| val.value == value }
          if enum_value && (was_authed = enum_value.authorized?(ctx))
            enum_value.graphql_name
          else
            raise self::UnresolvedValueError.new(enum: self, value: value, context: ctx, authorized: was_authed)
          end
        end

        # Called by the runtime with incoming string representations from a query.
        # It will match the string to a configured by name or by Ruby value.
        #
        # **Parameters**
        #
        # - `value_name` (`String, Object`) — A string from a GraphQL query, or a Ruby value matching a `value(..., value: ...)` configuration
        # - `ctx` (`GraphQL::Query::Context`)
        #
        # **Raises**
        #
        # - `GraphQL::UnauthorizedEnumValueError` — if an [EnumValue](rdoc-ref:EnumValue) matches but returns false for `.authorized?`. Goes to [Schema.unauthorized_object](rdoc-ref:Schema.unauthorized_object).
        #
        # **Returns**
        #
        # - `Object` — The Ruby value for the matched [GraphQL::Schema::EnumValue](rdoc-ref:GraphQL::Schema::EnumValue)
        #
        # :call-seq:
        #   coerce_input(String | Object value_name, GraphQL::Query::Context ctx) -> Object
        def coerce_input(value_name, ctx)
          all_values = ctx.types ? ctx.types.enum_values(self) : values.each_value

          # This tries matching by incoming GraphQL string, then checks Ruby-defined values
          if v = (all_values.find { |val| val.graphql_name == value_name } || all_values.find { |val| val.value == value_name })
            if v.authorized?(ctx)
              v.value
            else
              raise GraphQL::UnauthorizedEnumValueError.new(type: self, enum_value: v, context: ctx)
            end
          else
            nil
          end
        end

        def inherited(child_class)
          if child_class.name
            # Don't assign a custom error class to anonymous classes
            # because they would end up with names like `#<Class0x1234>::UnresolvedValueError` which messes up bug trackers
            child_class.const_set(:UnresolvedValueError, Class.new(Schema::Enum::UnresolvedValueError))
          end
          child_class.class_exec { @value_methods = nil }
          super
        end

        private

        def own_values
          @own_values ||= {}
        end

        def generate_value_method(value, configured_value_method)
          return if configured_value_method == false

          value_method_name = configured_value_method || value.graphql_name.downcase

          if respond_to?(value_method_name.to_sym)
            warn "Failed to define value method for :#{value_method_name}, because " \
              "#{value.owner.name || value.owner.graphql_name} already responds to that method. Use `value_method:` to override the method name " \
              "or `value_method: false` to disable Enum value method generation."
            return
          end

          define_singleton_method(value_method_name) { value.graphql_name }
        end
      end

      enum_value_class(GraphQL::Schema::EnumValue)
    end
  end
end
