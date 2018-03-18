# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Support for legacy `accepts_definitions` functions.
      #
      # @example Applying a function to base object class
      #   class BaseObject < GraphQL::Schema::Object
      #     accepts_definition :permission_level, -> (defn, level) {
      #       defn.metadata[:permission_level] = level
      #     }
      #   end
      #
      #   class Account < BaseObject
      #     permission_level 1
      #   end
      #
      #   Account.permission_level # => 1
      #   Account.graphql_definition.metadata[:permission_level] # => 1
      module AcceptsDefinition
        def self.extended(child)
          # I tried to use `super`, but super isn't quite right
          # since the method is defined in the same class itself,
          # not the superclass
          child.class_eval do
            if child.respond_to?(:to_graphql)
              class << self
                alias :to_graphql_without_accepts_definitions :to_graphql
                alias :to_graphql :to_graphql_with_accepts_definitions
              end
            else
              include(AcceptsDefinition)
              alias :initialize_without_accepts_definitions :initialize
              alias :initialize :initialize_with_accepts_definitions

              alias :to_graphql_without_accepts_definitions :to_graphql
              alias :to_graphql :to_graphql_with_accepts_definitions
            end
          end
        end

        def initialize_with_accepts_definitions(*args, **kwargs, &block)
          self.class.accepts_definition_methods.each do |method_name|
            if kwargs.key?(method_name)
              value = kwargs.delete(method_name)
              instance_variable_set("@#{method_name}_args", [value])
            end
          end
          initialize_without_accepts_definitions(*args, **kwargs, &block)
        end

        def accepts_definition(name)
          @accepts_definition_methods ||= []
          @accepts_definition_methods << name
          ivar_name = "@#{name}_args"
          define_singleton_method(name) do |*args|
            if args.any?
              instance_variable_set(ivar_name, args)
            end
            instance_variable_get(ivar_name)
          end

          define_method(name) do |*args|
            if args.any?
              instance_variable_set(ivar_name, args)
            end
            instance_variable_get(ivar_name)
          end
        end

        def to_graphql_with_accepts_definitions
          defn = to_graphql_without_accepts_definitions
          accepts_definition_methods.each do |method_name|
            value = instance_variable_get("@#{method_name}_args")
            if !value.nil?
              defn = defn.redefine { public_send(method_name, *value) }
            end
          end
          defn
        end

        def accepts_definition_methods
          @accepts_definition_methods ||= []
          sc = self.is_a?(Class) ? superclass : self.class.superclass
          @accepts_definition_methods + (sc.respond_to?(:accepts_definition_methods) ? sc.accepts_definition_methods : [])
        end
      end
    end
  end
end
