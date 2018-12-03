# frozen_string_literal: true
module GraphQL
  module Execution
    class Lazy
      # Helpers for dealing with data structures containing {Lazy} instances
      # @api private
      module Resolve
        # Mutate `value`, replacing {Lazy} instances in place with their resolved values
        # @return [void]

        # This object can be passed like an array, but it doesn't allocate an
        # array until it's used.
        #
        # There's one crucial difference: you have to _capture_ the result
        # of `#<<`. (This _works_ with arrays but isn't required, since it has a side-effect.)
        # @api private
        module NullAccumulator
          def self.<<(item)
            [item]
          end

          def self.empty?
            true
          end

          def self.map
            self
          end
        end

        def self.resolve(value)
          lazies = resolve_in_place(value)
          deep_sync(lazies)
        end

        def self.resolve_interpreter_result(result)
          lazies = interpreter_each_lazy(NullAccumulator, result)
          interpreter_resolve_all(lazies)
        end

        def self.interpreter_resolve_all(result)
          puts "SYNCING #{result.size}:"
          result.each do |r|
            puts "   - #{r.field.path.ljust(20)} @ #{r.path}"
          end
          lazy_results = result.map do |l|
            puts "SYNC #{l.field.path.ljust(20)} @ #{l.path}"
            l.value
          end

          next_lazies = interpreter_each_lazy(NullAccumulator, lazy_results)
          if !next_lazies.empty?
            interpreter_resolve_all(next_lazies)
          end
        end

        def self.interpreter_each_lazy(acc, value)
          case value
          when Hash
            if value.values.any? { |v| v.is_a?(Lazy) }
              p "Hash: #{value.keys}"
            end
            value.each do |k, v|
              acc = interpreter_each_lazy(acc, v)
            end
            acc
          when Array
            if value.any? { |v| v.is_a?(Lazy) }
              p "Array: #{value.size}"
            end
            value.each { |i|
              acc = interpreter_each_lazy(acc, i)
            }
            acc
          when Lazy
            p "Plain Lazy"
            acc << value
          else
            # Some application value
            acc
          end
        end

        def self.resolve_in_place(value)
          acc = each_lazy(NullAccumulator, value)

          if acc.empty?
            Lazy::NullResult
          else
            Lazy.new {
              acc.each_with_index { |ctx, idx|
                acc[idx] = ctx.value.value
              }
              resolve_in_place(acc)
            }
          end
        end

        # If `value` is a collection,
        # add any {Lazy} instances in the collection
        # to `acc`
        # @return [void]
        def self.each_lazy(acc, value)
          case value
          when Hash
            value.each do |key, field_result|
              acc = each_lazy(acc, field_result)
            end
          when Array
            value.each do |field_result|
              acc = each_lazy(acc, field_result)
            end
          when Query::Context::SharedMethods
            field_value = value.value
            case field_value
            when Lazy
              acc = acc << value
            when Enumerable # shortcut for Hash & Array
              acc = each_lazy(acc, field_value)
            end
          end

          acc
        end

        # Traverse `val`, triggering resolution for each {Lazy}.
        # These {Lazy}s are expected to mutate their owner data structures
        # during resolution! (They're created with the `.then` calls in `resolve_in_place`).
        # @return [void]
        def self.deep_sync(val)
          case val
          when Lazy
            deep_sync(val.value)
          when Array
            val.each { |v| deep_sync(v.value) }
          when Hash
            val.each { |k, v| deep_sync(v.value) }
          end
        end
      end
    end
  end
end
