# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Support for legacy `accepts_definitions` functions.
      #
      # Keep the legacy handler hooked up. Class-based types and fields
      # will call those legacy handlers during their `.to_graphql`
      # methods.
      #
      # This can help out while transitioning from one to the other.
      # Eventually, `GraphQL::{X}Type` objects will be removed entirely,
      # But this can help during the transition.
      #
      # @example Applying a function to base object class
      #   # Here's the legacy-style config, which we're calling back to:
      #   GraphQL::ObjectType.accepts_definition({
      #     permission_level: ->(defn, value) { defn.metadata[:permission_level] = value }
      #   })
      #
      #   class BaseObject < GraphQL::Schema::Object
      #     # Setup a named pass-through to the legacy config functions
      #     accepts_definition :permission_level
      #   end
      #
      #   class Account < BaseObject
      #     # This value will be passed to the legacy handler:
      #     permission_level 1
      #   end
      #
      #   # The class gets a reader method which returns the args,
      #   # only marginally useful.
      #   Account.permission_level # => [1]
      #
      #   # The legacy handler is called, as before:
      #   Account.graphql_definition.metadata[:permission_level] # => 1
      module AcceptsDefinition
        def self.included(child)
          child.extend(ClassMethods)
          child.prepend(ToGraphQLExtension)
          child.prepend(InitializeExtension)
        end

        def self.extended(child)
          child.extend(ClassMethods)
          # I tried to use `super`, but super isn't quite right
          # since the method is defined in the same class itself,
          # not the superclass
          child.class_eval do
            class << self
              prepend(ToGraphQLExtension)
            end
          end
        end

        module ClassMethods
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

          def accepts_definition_methods
            @accepts_definition_methods ||= []
            sc = self.is_a?(Class) ? superclass : self.class.superclass
            @accepts_definition_methods + (sc.respond_to?(:accepts_definition_methods) ? sc.accepts_definition_methods : [])
          end
        end

        module ToGraphQLExtension
          def to_graphql
            defn = super
            accepts_definition_methods.each do |method_name|
              value = instance_variable_get("@#{method_name}_args")
              if !value.nil?
                defn = defn.redefine { public_send(method_name, *value) }
              end
            end
            defn
          end
        end

        module InitializeExtension
          def initialize(*args, **kwargs, &block)
            self.class.accepts_definition_methods.each do |method_name|
              if kwargs.key?(method_name)
                value = kwargs.delete(method_name)
                if !value.is_a?(Array)
                  value = [value]
                end
                instance_variable_set("@#{method_name}_args", value)
              end
            end
            super(*args, **kwargs, &block)
          end

          def accepts_definition_methods
            self.class.accepts_definition_methods
          end
        end
      end
    end
  end
end
