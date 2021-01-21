# frozen_string_literal: true
module GraphQL
  module Define
    # @api deprecated
    module InstanceDefinable
      module DeprecatedDefine
        def define(**kwargs, &block)
          deprecated_caller = caller(1, 1).first
          if deprecated_caller.include?("lib/graphql")
            deprecated_caller = caller(2, 10).find { |c| !c.include?("lib/graphql") }
          end

          if deprecated_caller
            GraphQL::Deprecation.warn <<-ERR
#{self}.define will be removed in GraphQL-Ruby 2.0; use a class-based definition instead. See https://graphql-ruby.org/schema/class_based_api.html.
  -> called from #{deprecated_caller}
ERR
          end
          deprecated_define(**kwargs, &block)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.ensure_defined(:metadata)
      end

      # @api deprecated
      def metadata
        @metadata ||= {}
      end

      # @api deprecated
      def deprecated_define(**kwargs, &block)
        # make sure the previous definition_proc was executed:
        ensure_defined
        stash_dependent_methods
        @pending_definition = Definition.new(kwargs, block)
        nil
      end

      # @api deprecated
      def define(**kwargs, &block)
        deprecated_define(**kwargs, &block)
      end

      # @api deprecated
      def redefine(**kwargs, &block)
        ensure_defined
        new_inst = self.dup
        new_inst.deprecated_define(**kwargs, &block)
        new_inst
      end

      def initialize_copy(other)
        super
        @metadata = other.metadata.dup
      end

      private

      # Run the definition block if it hasn't been run yet.
      # This can only be run once: the block is deleted after it's used.
      # You have to call this before using any value which could
      # come from the definition block.
      # @return [void]
      def ensure_defined
        if @pending_definition
          defn = @pending_definition
          @pending_definition = nil

          revive_dependent_methods

          begin
            defn_proxy = DefinedObjectProxy.new(self)
            # Apply definition from `define(...)` kwargs
            defn.define_keywords.each do |keyword, value|
              # Don't splat string hashes, which blows up on Rubies before 2.7
              if value.is_a?(Hash) && value.each_key.all? { |k| k.is_a?(Symbol) }
                defn_proxy.public_send(keyword, **value)
              else
                defn_proxy.public_send(keyword, value)
              end
            end
            # and/or apply definition from `define { ... }` block
            if defn.define_proc
              defn_proxy.instance_eval(&defn.define_proc)
            end
          rescue StandardError
            # The definition block failed to run, so make this object pending again:
            stash_dependent_methods
            @pending_definition = defn
            raise
          end
        end
        nil
      end

      # Take the pending methods and put them back on this object's singleton class.
      # This reverts the process done by {#stash_dependent_methods}
      # @return [void]
      def revive_dependent_methods
        pending_methods = @pending_methods
        self.singleton_class.class_eval {
          pending_methods.each do |method|
            undef_method(method.name) if method_defined?(method.name)
            define_method(method.name, method)
          end
        }
        @pending_methods = nil
      end

      # Find the method names which were declared as definition-dependent,
      # then grab the method definitions off of this object's class
      # and store them for later.
      #
      # Then make a dummy method for each of those method names which:
      #
      # - Triggers the pending definition, if there is one
      # - Calls the same method again.
      #
      # It's assumed that {#ensure_defined} will put the original method definitions
      # back in place with {#revive_dependent_methods}.
      # @return [void]
      def stash_dependent_methods
        method_names = self.class.ensure_defined_method_names
        @pending_methods = method_names.map { |n| self.class.instance_method(n) }
        self.singleton_class.class_eval do
          method_names.each do |method_name|
            undef_method(method_name) if method_defined?(method_name)
            define_method(method_name) { |*args, &block|
              ensure_defined
              self.send(method_name, *args, &block)
            }
          end
        end
      end

      class Definition
        attr_reader :define_keywords, :define_proc
        def initialize(define_keywords, define_proc)
          @define_keywords = define_keywords
          @define_proc = define_proc
        end
      end

      module ClassMethods
        # Create a new instance
        # and prepare a definition using its {.definitions}.
        # @api deprecated
        # @param kwargs [Hash] Key-value pairs corresponding to defininitions from `accepts_definitions`
        # @param block [Proc] Block which calls helper methods from `accepts_definitions`
        def deprecated_define(**kwargs, &block)
          instance = self.new
          instance.deprecated_define(**kwargs, &block)
          instance
        end

        # @api deprecated
        def define(**kwargs, &block)
          instance = self.new
          instance.define(**kwargs, &block)
          instance
        end

        # Attach definitions to this class.
        # Each symbol in `accepts` will be assigned with `{key}=`.
        # The last entry in accepts may be a hash of name-proc pairs for custom definitions.
        def accepts_definitions(*accepts)
          new_assignments = if accepts.last.is_a?(Hash)
            accepts.pop.dup
          else
            {}
          end

          accepts.each do |key|
            new_assignments[key] = AssignAttribute.new(key)
          end

          @own_dictionary = own_dictionary.merge(new_assignments)
        end

        def ensure_defined(*method_names)
          @ensure_defined_method_names ||= []
          @ensure_defined_method_names.concat(method_names)
          nil
        end

        def ensure_defined_method_names
          own_method_names = @ensure_defined_method_names || []
          if superclass.respond_to?(:ensure_defined_method_names)
            superclass.ensure_defined_method_names + own_method_names
          else
            own_method_names
          end
        end

        # @return [Hash] combined definitions for self and ancestors
        def dictionary
          if superclass.respond_to?(:dictionary)
            own_dictionary.merge(superclass.dictionary)
          else
            own_dictionary
          end
        end

        # @return [Hash] definitions for this class only
        def own_dictionary
          @own_dictionary ||= {}
        end
      end

      class AssignMetadataKey
        def initialize(key)
          @key = key
        end

        def call(defn, value = true)
          defn.metadata[@key] = value
        end
      end

      class AssignAttribute
        extend GraphQL::Ruby2Keywords

        def initialize(attr_name)
          @attr_assign_method = :"#{attr_name}="
        end

        # Even though we're just using the first value here,
        # We have to add a splat here to use `ruby2_keywords`,
        # so that it will accept a `[{}]` input from the caller.
        def call(defn, *value)
          defn.public_send(@attr_assign_method, value.first)
        end
        ruby2_keywords :call
      end
    end
  end
end
