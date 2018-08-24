# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      include GraphQL::Schema::Member::GraphQLTypeNames

      module DefinitionMethods
        include GraphQL::Schema::Member::CachedGraphQLDefinition
        include GraphQL::Relay::TypeExtensions
        include GraphQL::Schema::Member::BaseDSLMethods
        include GraphQL::Schema::Member::TypeSystemHelpers
        include GraphQL::Schema::Member::HasFields
        include GraphQL::Schema::Member::HasPath
        include GraphQL::Schema::Member::RelayShortcuts
        include GraphQL::Schema::Member::Scoped

        # Methods defined in this block will be:
        # - Added as class methods to this interface
        # - Added as class methods to all child interfaces
        def definition_methods(&block)
          self::DefinitionMethods.module_eval(&block)
        end

        # The interface is visible if any of its possible types are visible
        def visible?(context)
          context.schema.possible_types(self).each do |type|
            if context.schema.visible?(type, context)
              return true
            end
          end
          false
        end

        # The interface is accessible if any of its possible types are accessible
        def accessible?(context)
          context.schema.possible_types(self).each do |type|
            if context.schema.accessible?(type, context)
              return true
            end
          end
          false
        end

        # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
        def included(child_class)
          if !child_class.is_a?(Class)
            # In this case, it's been included into another interface.
            # This is how interface inheritance is implemented

            # We need this before we can call `own_interfaces`
            child_class.extend(Schema::Interface::DefinitionMethods)

            child_class.own_interfaces << self
            child_class.interfaces.reverse_each do |interface_defn|
              child_class.extend(interface_defn::DefinitionMethods)
            end

            # Use an instance variable to tell whether it's been included previously or not;
            # You can't use constant detection because constants are brought into scope
            # by `include`, which has already happened at this point.
            if !child_class.instance_variable_defined?(:@_definition_methods)
              defn_methods_module = Module.new
              child_class.instance_variable_set(:@_definition_methods, defn_methods_module)
              child_class.const_set(:DefinitionMethods, defn_methods_module)
              child_class.extend(child_class::DefinitionMethods)
            end
          elsif child_class < GraphQL::Schema::Object
            # This is being included into an object type, make sure it's using `implements(...)`
            backtrace_line = caller(0, 10).find { |line| line.include?("schema/object.rb") && line.include?("in `implements'") }
            if !backtrace_line
              raise "Attach interfaces using `implements(#{self})`, not `include(#{self})`"
            end
          end

          super
        end

        def orphan_types(*types)
          if types.any?
            @orphan_types = types
          else
            all_orphan_types = @orphan_types || []
            all_orphan_types += super if defined?(super)
            all_orphan_types.uniq
          end
        end

        def to_graphql
          type_defn = GraphQL::InterfaceType.new
          type_defn.name = graphql_name
          type_defn.description = description
          type_defn.orphan_types = orphan_types
          fields.each do |field_name, field_inst|
            field_defn = field_inst.graphql_definition
            type_defn.fields[field_defn.name] = field_defn
          end
          type_defn.metadata[:type_class] = self
          if respond_to?(:resolve_type)
            type_defn.resolve_type = method(:resolve_type)
          end
          type_defn
        end

        def kind
          GraphQL::TypeKinds::INTERFACE
        end

        protected

        def own_interfaces
          @own_interfaces ||= []
        end

        def interfaces
          own_interfaces + (own_interfaces.map { |i| i.own_interfaces }).flatten
        end
      end

      # Extend this _after_ `DefinitionMethods` is defined, so it will be used
      extend GraphQL::Schema::Member::AcceptsDefinition

      extend DefinitionMethods

      def unwrap
        self
      end
    end
  end
end
