# frozen_string_literal: true

module GraphQL
  module Define
    # This object delegates most methods to a dictionary of functions, {@dictionary}.
    # {@target} is passed to the specified function, along with any arguments and block.
    # This allows a method-based DSL without adding methods to the defined class.
    class DefinedObjectProxy
      extend GraphQL::Ruby2Keywords
      # The object which will be defined by definition functions
      attr_reader :target

      def initialize(target)
        @target = target
        @dictionary = target.class.dictionary
      end

      # Provides shorthand access to GraphQL's built-in types
      def types
        GraphQL::Define::TypeDefiner.instance
      end

      # Allow `plugin` to perform complex initialization on the definition.
      # Calls `plugin.use(defn, **kwargs)`.
      # @param plugin [<#use(defn, **kwargs)>] A plugin object
      # @param kwargs [Hash] Any options for the plugin
      def use(plugin, **kwargs)
        # https://bugs.ruby-lang.org/issues/10708
        if kwargs == {}
          plugin.use(self)
        else
          plugin.use(self, **kwargs)
        end
      end

      # Lookup a function from the dictionary and call it if it's found.
      def method_missing(name, *args, &block)
        definition = @dictionary[name]
        if definition
          definition.call(@target, *args, &block)
        else
          msg = "#{@target.class.name} can't define '#{name}'"
          raise NoDefinitionError, msg, caller
        end
      end
      ruby2_keywords :method_missing

      def respond_to_missing?(name, include_private = false)
        @dictionary[name] || super
      end
    end
  end
end
