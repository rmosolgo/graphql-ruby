module GraphQL
  class Schema
    class Mask
      def initialize(&block)
        @filter = block
      end

      def apply(query)
        Warden.new(self, query)
      end

      def visible?(member)
        !@filter.call(member)
      end

      # A Mask implementation that shows everything as visible
      module NullMask
        module_function

        def apply(query)
          Warden.new(self, query)
        end

        def visible?(member)
          true
        end
      end

      # Restrict access to `@schema`'s members based on `@mask` & `@query`'s context
      class Warden
        # @param mask [<#visible?(member)>]
        # @param query [GraphQL::Query]
        def initialize(mask, query)
          @mask = mask
          @query = query
          @schema = query.schema
        end

        # @yieldparam [GraphQL::BaseType] Each type in the schema
        def each_type
          if block_given?
            @schema.types.each do |name, type_defn|
              if visible_type?(type_defn)
                yield(type_defn)
              end
            end
          else
            enum_for(:each_type)
          end
        end

        # @return [GraphQL::BaseType, nil] The type named `type_name`, if it exists (else `nil`)
        def get_type(type_name)
          type_defn = @schema.types.fetch(type_name, nil)
          if type_defn && visible_type?(type_defn)
            type_defn
          else
            nil
          end
        end

        # @return [GraphQL::Field, nil] The field named `field_name` on `parent_type`, if it exists
        def get_field(parent_type, field_name)
          # TODO: move `Schema#get_field` here?
          field_defn = @schema.get_field(parent_type, field_name)
          if field_defn && visible_field?(field_defn)
            field_defn
          else
            nil
          end
        end

        # @return [Array<GraphQL::BaseType>] The types which may be member of `type_defn`
        def possible_types(type_defn)
          @schema.possible_types(type_defn).select { |t| visible_type?(t) }
        end

        # @param type_defn [GraphQL::ObjectType, GraphQL::InterfaceType]
        # @return [Array<GraphQL::Field>] Fields on `type_defn`
        def each_field(type_defn)
          if block_given?
            type_defn.all_fields.each do |field_defn|
              if visible_field?(field_defn)
                yield(field_defn)
              end
            end
          else
            enum_for(:each_field, type_defn)
          end
        end

        # @param argument_owner [GraphQL::Field, GraphQL::InputObjectType]
        # @yieldparam [GraphQL::Argument] Each argument on `argument_owner`
        def each_argument(argument_owner)
          if block_given?
            argument_owner.arguments.each do |name, arg_defn|
              if visible_argument?(arg_defn)
                yield(arg_defn)
              end
            end
          else
            enum_for(:each_argument, argument_owner)
          end
        end

        # @yieldparam [GraphQL::EnumType::EnumValue] Each member of `enum_defn`
        def each_enum_value(enum_defn)
          if block_given?
            enum_defn.values.each do |name, enum_value_defn|
              if visible_enum_value?(enum_value_defn)
                yield(enum_value_defn)
              end
            end
          else
            enum_for(:each_enum_value, enum_defn)
          end
        end

        # @param obj_type [GraphQL::ObjectType]
        # @yieldparam [GraphQL::InterfaceType] Each of `obj_type`'s interfaces
        def each_interface(obj_type)
          if block_given?
            obj_type.interfaces.each do |int_defn|
              if visible_type?(int_defn)
                yield(int_defn)
              end
            end
          else
            enum_for(:each_interface, obj_type)
          end
        end

        private

        def visible_field?(field_defn)
          visible?(field_defn) && visible?(field_defn.type.unwrap)
        end

        def visible_type?(type_defn)
          visible?(type_defn)
        end

        def visible_enum_value?(enum_value_defn)
          visible?(enum_value_defn)
        end

        def visible_argument?(arg_defn)
          visible?(arg_defn) && visible?(arg_defn.type.unwrap)
        end

        def visible?(member)
          @mask.visible?(member)
        end
      end
    end
  end
end
