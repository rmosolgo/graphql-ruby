# frozen_string_literal: true
module GraphQL
  module Define
    # This module provides the `.define { ... }` API for
    # {GraphQL::BaseType}, {GraphQL::Field} and others.
    #
    # Calling `.accepts_definitions(...)` creates:
    #
    # - a keyword to the `.define` method
    # - a helper method in the `.define { ... }` block
    #
    # The `.define { ... }` block will be called lazily. To be sure it has been
    # called, use the private method `#ensure_defined`. That will call the
    # definition block if it hasn't been called already.
    #
    # The goals are:
    #
    # - Minimal overhead in consuming classes
    # - Independence between consuming classes
    # - Extendable by third-party libraries without monkey-patching or other nastiness
    #
    # @example Make a class definable
    #   class Car
    #     include GraphQL::Define::InstanceDefinable
    #     attr_accessor :make, :model, :doors
    #     accepts_definitions(
    #       # These attrs will be defined with plain setters, `{attr}=`
    #       :make, :model,
    #       # This attr has a custom definition which applies the config to the target
    #       doors: ->(car, doors_count) { doors_count.times { car.doors << Door.new } }
    #     )
    #     ensure_defined(:make, :model, :doors)
    #
    #     def initialize
    #       @doors = []
    #     end
    #   end
    #
    #   class Door; end;
    #
    #   # Create an instance with `.define`:
    #   subaru_baja = Car.define do
    #     make "Subaru"
    #     model "Baja"
    #     doors 4
    #   end
    #
    #   # The custom proc was applied:
    #   subaru_baja.doors #=> [<Door>, <Door>, <Door>, <Door>]
    #
    # @example Extending the definition of a class
    #   # Add some definitions:
    #   Car.accepts_definitions(all_wheel_drive: GraphQL::Define.assign_metadata_key(:all_wheel_drive))
    #
    #   # Use it in a definition
    #   subaru_baja = Car.define do
    #     # ...
    #     all_wheel_drive true
    #   end
    #
    #   # Access it from metadata
    #   subaru_baja.metadata[:all_wheel_drive] # => true
    #
    # @example Extending the definition of a class via a plugin
    #   # A plugin is any object that responds to `.use(definition)`
    #   module SubaruCar
    #     extend self
    #
    #     def use(defn)
    #       # `defn` has the same methods as within `.define { ... }` block
    #       defn.make "Subaru"
    #       defn.doors 4
    #     end
    #   end
    #
    #   # Use the plugin within a `.define { ... }` block
    #   subaru_baja = Car.define do
    #     use SubaruCar
    #     model 'Baja'
    #   end
    #
    #   subaru_baja.make # => "Subaru"
    #   subaru_baja.doors # => [<Door>, <Door>, <Door>, <Door>]
    #
    # @example Making a copy with an extended definition
    #   # Create an instance with `.define`:
    #   subaru_baja = Car.define do
    #     make "Subaru"
    #     model "Baja"
    #     doors 4
    #   end
    #
    #   # Then extend it with `#redefine`
    #   two_door_baja = subaru_baja.redefine do
    #     doors 2
    #   end
    module InstanceDefinable
      def self.included(base)
        base.extend(ClassMethods)
        base.ensure_defined(:metadata)
      end

      # `metadata` can store arbitrary key-values with an object.
      #
      # @return [Hash<Object, Object>] Hash for user-defined storage
      def metadata
        @metadata ||= {}
      end

      # Mutate this instance using functions from its {.definition}s.
      # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
      #
      # Note that the block is not called right away -- instead, it's deferred until
      # one of the defined fields is needed.
      # @return [void]
      def define(**kwargs, &block)
        # make sure the previous definition_proc was executed:
        ensure_defined
        stash_dependent_methods
        @pending_definition = Definition.new(kwargs, block)
        nil
      end

      # Shallow-copy this object, then apply new definitions to the copy.
      # @see {#define} for arguments
      # @return [InstanceDefinable] A new instance, with any extended definitions
      def redefine(**kwargs, &block)
        ensure_defined
        new_inst = self.dup
        new_inst.define(**kwargs, &block)
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
              defn_proxy.public_send(keyword, value)
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
        # @param kwargs [Hash] Key-value pairs corresponding to defininitions from `accepts_definitions`
        # @param block [Proc] Block which calls helper methods from `accepts_definitions`
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
        def initialize(attr_name)
          @attr_assign_method = :"#{attr_name}="
        end

        def call(defn, value)
          defn.public_send(@attr_assign_method, value)
        end
      end
    end
  end
end
