# frozen_string_literal: true
# typed: true
module GraphQL
  class Query
    class Context
      class ScopedContext
        # Under Execution::Next, the FieldResolveStep (or ResolverFrame) currently calling a resolver in this Fiber.
        NEXT_STEP_KEY = :__graphql_next_scoped_step

        # A `resolver:` class runs as its own step, so it carries its object's index instead of using the field step's.
        ResolverFrame = Struct.new(:step, :index) # :nodoc:
        NOT_FOUND = Object.new.freeze
        private_constant :NOT_FOUND

        def initialize(query_context)
          @query_context = query_context
          @scoped_contexts = nil
          @all_keys = nil
          # Execution::Next has no per-object path, so its scopes hang off result hashes instead:
          # result hash => { response key => scoped values set by that field on that object }
          @next_scopes = nil
          # child result hash => [the result hash it belongs to, the response key of the field that produced it]
          @next_parents = nil
          # list result => the result hash whose field returned the list
          @next_list_owners = nil
        end

        def merged_context
          if (scope = current_next_scope)
            owners, field_key, field_definition = scope
            merged = nil #: Hash[untyped, untyped]?
            owners.each do |owner|
              owner_merged = next_merged_context(owner, field_key)
              if merged.nil?
                merged = owner_merged
              elsif merged != owner_merged
                raise_ambiguous(nil, field_definition)
              end
            end
            merged || GraphQL::EmptyObjects::EMPTY_HASH
          elsif @scoped_contexts.nil?
            GraphQL::EmptyObjects::EMPTY_HASH
          else
            merged_ctx = {} #: untyped
            each_present_path_ctx do |path_ctx|
              merged_ctx = path_ctx.merge(merged_ctx)
            end
            merged_ctx
          end
        end

        # With neither `at:` nor `next_owners:`, writes to the scope of the field being resolved right now.
        def merge!(hash, at: nil, next_owners: nil, next_field_key: nil)
          @all_keys ||= Set.new
          @all_keys.merge(hash.keys)
          if at.nil? && next_owners.nil?
            if (scope = current_next_scope)
              next_owners, next_field_key, _field_definition = scope
            else
              at = current_path
            end
          end

          if next_owners
            scopes = @next_scopes ||= {}.compare_by_identity
            next_owners.each do |owner|
              by_key = scopes[owner] ||= {}
              this_scoped_ctx = by_key[next_field_key] ||= {}
              this_scoped_ctx.merge!(hash)
            end
          else
            ctx = @scoped_contexts ||= {}
            at.each do |path_part|
              ctx = ctx[path_part] ||= { parent: ctx }
            end
            this_scoped_ctx = ctx[:scoped_context] ||= {}
            this_scoped_ctx.merge!(hash)
          end
        end

        def key?(key)
          if @all_keys && @all_keys.include?(key)
            !lookup(key).equal?(NOT_FOUND)
          else
            false
          end
        end

        def [](key)
          value = lookup(key)
          value.equal?(NOT_FOUND) ? nil : value
        end

        def current_path
          @query_context.current_path || GraphQL::EmptyObjects::EMPTY_ARRAY
        end

        def dig(key, *other_keys)
          found_value = lookup(key)
          if found_value.equal?(NOT_FOUND)
            nil
          elsif !other_keys.empty?
            found_value.dig(*other_keys)
          else
            found_value
          end
        end

        # Returns `[owner_results, response_key, field_definition]` while Execution::Next is calling a resolver for this query.
        def current_next_scope # :nodoc:
          step = Fiber[NEXT_STEP_KEY]
          index = nil
          if step.is_a?(ResolverFrame)
            index = step.index
            step = step.step
          end
          if step && step.scoped_context.equal?(self)
            owners = index ? step.scoped_context_owners(index) : step.scoped_context_owners
            # Writing through a scope means children need parent links to find it, so start tracking them.
            @next_scopes ||= {}.compare_by_identity
            [owners, step.key, step.field_definition]
          end
        end

        # True once Execution::Next has written or captured a per-object scope, so new results need parent links.
        def tracking_next_results? # :nodoc:
          !@next_scopes.nil?
        end

        # Records where an Execution::Next result was produced, so scope lookups can walk up from it.
        def link_next_result(container, child, field_key) # :nodoc:
          owner = (@next_list_owners && @next_list_owners[container]) || container
          if child.is_a?(Array)
            (@next_list_owners ||= {}.compare_by_identity)[child] = owner
          else
            (@next_parents ||= {}.compare_by_identity)[child] = [owner, field_key]
          end
          nil
        end

        private

        def lookup(key)
          if (scope = current_next_scope)
            owners, field_key, field_definition = scope
            found = NOT_FOUND #: untyped
            owners.each_with_index do |owner, idx|
              owner_value = next_lookup(owner, field_key, key)
              if idx == 0
                found = owner_value
              elsif !owner_value.equal?(found) && owner_value != found
                raise_ambiguous(key, field_definition)
              end
            end
            found
          else
            each_present_path_ctx do |path_ctx|
              if path_ctx.key?(key)
                return path_ctx[key]
              end
            end
            NOT_FOUND
          end
        end

        def next_lookup(owner, field_key, key)
          if (scopes = @next_scopes)
            result = owner
            result_key = field_key
            while result
              if (by_key = scopes[result]) && (values = by_key[result_key]) && values.key?(key)
                return values[key]
              end
              result, result_key = @next_parents && @next_parents[result]
            end
          end

          if (root_ctx = @scoped_contexts && @scoped_contexts[:scoped_context]) && root_ctx.key?(key)
            root_ctx[key]
          else
            NOT_FOUND
          end
        end

        def next_merged_context(owner, field_key)
          chain = []
          if (scopes = @next_scopes)
            result = owner
            result_key = field_key
            while result
              if (by_key = scopes[result]) && (values = by_key[result_key])
                chain << values
              end
              result, result_key = @next_parents && @next_parents[result]
            end
          end
          merged = (@scoped_contexts && @scoped_contexts[:scoped_context]).dup || {}
          chain.reverse_each { |values| merged.merge!(values) }
          merged
        end

        def raise_ambiguous(key, field_definition)
          subject = key ? "Scoped context value #{key.inspect}" : "Scoped context"
          raise GraphQL::Error, "#{subject} differs between the objects passed to #{field_definition.path}, so a batched resolver can't read it. Resolve this field per object (for example, with `resolve_each:`) to read scoped context."
        end

        # Start at the current location,
        # but look up the tree for previously-assigned scoped values
        def each_present_path_ctx
          ctx = @scoped_contexts
          if ctx.nil?
            # no-op
          else
            current_path.each do |path_part|
              if ctx.key?(path_part)
                ctx = ctx[path_part]
              else
                break
              end
            end

            while ctx
              if (scoped_ctx = ctx[:scoped_context])
                yield(scoped_ctx)
              end
              ctx = ctx[:parent]
            end
          end
        end
      end
    end
  end
end
