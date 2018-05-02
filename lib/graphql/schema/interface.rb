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

        # Methods defined in this block will be:
        # - Added as class methods to this interface
        # - Added as class methods to all child interfaces
        def definition_methods(&block)
          self::DefinitionMethods.module_eval(&block)
        end

        # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
        def included(child_class)
          if !child_class.is_a?(Class)
            # In this case, it's been included into another interface.
            # This is how interface inheritance is implemented
            
            if !child_class.const_defined?(:DefinitionMethods)
              child_class.const_set(:DefinitionMethods, Module.new)
              child_class.extend(child_class::DefinitionMethods)
            end

            if !(child_class.singleton_class < Schema::Interface::DefinitionMethods)
              # We need this before we can call `own_interfaces`
              child_class.extend(Schema::Interface::DefinitionMethods)
            end

            child_class.own_interfaces << self
            child_class.own_interfaces.each do |interface_defn|
              # Don't extend the interface's definition methods if we've already extended it
              next if child_class.singleton_class < interface_defn::DefinitionMethods
              child_class.extend(interface_defn::DefinitionMethods) 
            end
          elsif child_class < GraphQL::Schema::Object
            # This is being included into an object type, make sure it's using `implements(...)`
            backtrace_line = caller(0, 10).find { |line| line.include?("schema/object.rb") && line.include?("in `implements'")}
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
      end

      # Extend this _after_ `DefinitionMethods` is defined, so it will be used
      extend GraphQL::Schema::Member::AcceptsDefinition

      extend DefinitionMethods
    end
  end
end
