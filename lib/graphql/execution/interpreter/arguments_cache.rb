# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class ArgumentsCache
        def initialize(query)
          @query = query
          @dataloader = query.context.dataloader
          @storage = Hash.new do |h, argument_owner|
            args_by_parent = if argument_owner.arguments_statically_coercible?
              shared_values_cache = {}
              Hash.new do |h2, ignored_parent_object|
                h2[ignored_parent_object] = shared_values_cache
              end
            else
              Hash.new do |h2, parent_object|
                args_by_node = {}
                args_by_node.compare_by_identity
                h2[parent_object] = args_by_node
              end
            end
            args_by_parent.compare_by_identity
            h[argument_owner] = args_by_parent
          end
          @storage.compare_by_identity
        end

        def fetch(ast_node, argument_owner, parent_object)
          # This runs eagerly if no block is given
          @storage[argument_owner][parent_object][ast_node] ||= begin
            args_hash = self.class.prepare_args_hash(@query, ast_node)
            kwarg_arguments = argument_owner.coerce_arguments(parent_object, args_hash, @query.context)
            @query.after_lazy(kwarg_arguments) do |resolved_args|
              @storage[argument_owner][parent_object][ast_node] = resolved_args
            end
          end
        end

        class RunQueue
          def initialize(dataloader:, parent: nil, &when_finished)
            @dataloader = dataloader
            @parent = parent
            @steps = []
            if block_given?
              @when_finished = when_finished
            end
          end

          attr_reader :steps, :callbacks, :parent, :final_result

          def call
            catch do |terminate_with_flag|
              @terminate_with_flag = terminate_with_flag
              raise "Was already called" if @already_ran
              @already_ran = true
              @running_steps = 0
              @dataloader.append_job {
                while (step = steps.shift) || @running_steps > 0
                  if step
                    run_step(step, steps, running_steps)
                  else
                    @dataloader.yield
                  end
                end

                @final_result = @when_finished.call(@final_result)
                if parent
                  parent.running_steps -= 1
                end
              }
            end
            @final_result
          end

          def run_step(step, steps, running_steps)
            @running_steps += 1
            @dataloader.append_job {
              @final_result = step.call
              if !step.is_a?(self.class)
                @running_steps -= 1
              end
            }
          end

          def when_finished(&handler)
            @when_finished = handler
          end

          def terminate_with(arg)
            @final_result = arg
            throw @terminate_with_flag, arg
          end

          def spawn_child
            child_queue = self.class.new(parent: self, dataloader: @dataloader)
            steps << child_queue
            child_queue
          end

          protected

          attr_accessor :running_steps
        end

        # @yield [Interpreter::Arguments, Lazy<Interpreter::Arguments>] The finally-loaded arguments
        def dataload_for(ast_node, argument_owner, parent_object, &block)
          # First, normalize all AST or Ruby values to a plain Ruby hash
          arg_storage = @storage[argument_owner][parent_object]
          if (args = arg_storage[ast_node])
            yield(args)
          else
            args_hash = self.class.prepare_args_hash(@query, ast_node)
            child_queue = nil
            queue = RunQueue.new(dataloader: @query.context.dataloader) do
              resolved_args = child_queue.final_result
              arg_storage[ast_node] = resolved_args
              block.call(resolved_args)
            end
            queue.steps << -> {
              child_queue = queue.spawn_child
              argument_owner.coerce_arguments(parent_object, args_hash, @query.context, child_queue)
            }
            queue.call
          end
          nil
        end

        private

        NO_ARGUMENTS = GraphQL::EmptyObjects::EMPTY_HASH
        NO_VALUE_GIVEN = NOT_CONFIGURED

        def self.prepare_args_hash(query, ast_arg_or_hash_or_value)
          case ast_arg_or_hash_or_value
          when Hash
            if ast_arg_or_hash_or_value.empty?
              return NO_ARGUMENTS
            end
            args_hash = {}
            ast_arg_or_hash_or_value.each do |k, v|
              args_hash[k] = prepare_args_hash(query, v)
            end
            args_hash
          when Array
            ast_arg_or_hash_or_value.map { |v| prepare_args_hash(query, v) }
          when GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::InputObject, GraphQL::Language::Nodes::Directive
            if ast_arg_or_hash_or_value.arguments.empty? # rubocop:disable Development/ContextIsPassedCop -- AST-related
              return NO_ARGUMENTS
            end
            args_hash = {}
            ast_arg_or_hash_or_value.arguments.each do |arg| # rubocop:disable Development/ContextIsPassedCop -- AST-related
              v = prepare_args_hash(query, arg.value)
              if v != NO_VALUE_GIVEN
                args_hash[arg.name] = v
              end
            end
            args_hash
          when GraphQL::Language::Nodes::VariableIdentifier
            if query.variables.key?(ast_arg_or_hash_or_value.name)
              variable_value = query.variables[ast_arg_or_hash_or_value.name]
              prepare_args_hash(query, variable_value)
            else
              NO_VALUE_GIVEN
            end
          when GraphQL::Language::Nodes::Enum
            ast_arg_or_hash_or_value.name
          when GraphQL::Language::Nodes::NullValue
            nil
          else
            ast_arg_or_hash_or_value
          end
        end
      end
    end
  end
end
