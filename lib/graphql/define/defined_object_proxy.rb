# frozen_string_literal: true
module GraphQL
  module Define
    class DefinedObjectProxy
      def initialize(target)
        @target = target
        @dictionary = target.class.dictionary
      end

      def types
        GraphQL::Define::TypeDefiner.instance
      end

      def use(plugin, **kwargs)
        # https://bugs.ruby-lang.org/issues/10708
        if kwargs == {}
          plugin.use(self)
        else
          plugin.use(self, **kwargs)
        end
      end

      def method_missing(name, *args, &block)
        definition = @dictionary[name]
        if definition
          definition.call(@target, *args, &block)
        else
          msg = "#{@target.class.name} can't define '#{name}'"
          raise NoMethodError, msg, caller
        end
      end

      def respond_to_missing?(name, include_private = false)
        @dictionary[name] || super
      end
    end
  end
end
