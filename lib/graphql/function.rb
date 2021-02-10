# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class Function
    def self.inherited(subclass)
      GraphQL::Deprecation.warn "GraphQL::Function (used for #{subclass}) will be removed from GraphQL-Ruby 2.0, please upgrade to resolvers: https://graphql-ruby.org/fields/resolvers.html"
    end

    # @return [Hash<String => GraphQL::Argument>] Arguments, keyed by name
    def arguments
      self.class.arguments
    end

    # @return [GraphQL::BaseType] Return type
    def type
      self.class.type
    end

    # @return [Object] This function's resolver
    def call(obj, args, ctx)
      raise GraphQL::RequiredImplementationMissingError
    end

    # @return [String, nil]
    def description
      self.class.description
    end

    # @return [String, nil]
    def deprecation_reason
      self.class.deprecation_reason
    end

    # @return [Integer, Proc]
    def complexity
      self.class.complexity || 1
    end

    class << self
      # Define an argument for this function & its subclasses
      # @see {GraphQL::Field} same arguments as the `argument` definition helper
      # @return [void]
      def argument(*args, **kwargs, &block)
        argument = GraphQL::Argument.from_dsl(*args, **kwargs, &block)
        own_arguments[argument.name] = argument
        nil
      end

      # @return [Hash<String => GraphQL::Argument>] Arguments for this function class, including inherited arguments
      def arguments
        if parent_function?
          own_arguments.merge(superclass.arguments)
        else
          own_arguments.dup
        end
      end

      # Provides shorthand access to GraphQL's built-in types
      def types
        GraphQL::Define::TypeDefiner.instance
      end

      # Get or set the return type for this function class & descendants
      # @return [GraphQL::BaseType]
      def type(premade_type = nil, &block)
        if block_given?
          @type = GraphQL::ObjectType.define(&block)
        elsif premade_type
          @type = premade_type
        elsif parent_function?
          @type || superclass.type
        else
          @type
        end
      end

      def build_field(function)
        GraphQL::Field.define(
          arguments: function.arguments,
          complexity: function.complexity,
          type: function.type,
          resolve: function,
          description: function.description,
          function: function,
          deprecation_reason: function.deprecation_reason,
        )
      end

      # Class-level reader/writer which is inherited
      # @api private
      def self.inherited_value(name)
        self.class_eval <<-RUBY
          def #{name}(new_value = nil)
            if new_value
              @#{name} = new_value
            elsif parent_function?
              @#{name} || superclass.#{name}
            else
              @#{name}
            end
          end
        RUBY
      end

      # @!method description(new_value = nil)
      #   Get or set this class's description
      inherited_value(:description)
      # @!method deprecation_reason(new_value = nil)
      #   Get or set this class's deprecation_reason
      inherited_value(:deprecation_reason)
      # @!method complexity(new_value = nil)
      #   Get or set this class's complexity
      inherited_value(:complexity)

      private

      # Does this function inherit from another function?
      def parent_function?
        superclass <= GraphQL::Function
      end

      # Arguments defined on this class (not superclasses)
      def own_arguments
        @own_arguments ||= {}
      end
    end
  end
end
