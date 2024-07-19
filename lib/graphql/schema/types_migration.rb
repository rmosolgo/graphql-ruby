# frozen_string_literal: true
module GraphQL
  class Schema
    class TypesMigration < GraphQL::Schema::Subset
      def self.use(schema)
        schema.subset_class = self
      end

      class RuntimeTypesMismatchError < GraphQL::Error
        def initialize(method_called, warden_result, subset_result, method_args)
          super(<<~ERR)
            Mismatch in types for `##{method_called}(#{method_args.map(&:inspect).join(", ")})`:

            - Warden returned: #{humanize(warden_result)}

            - Subset returned: #{humanize(subset_result)}

            Update your `.visible?` implementation to make these implementations return the same value.

            See: https://graphql-ruby.org/authorization/visibility_migration.html
          ERR
        end

        private

        def humanize(val)
          case val
          when Array
            val.map { |v| humanize(v) }.sort.inspect
          when Module
            if val.respond_to?(:graphql_name)
              "#{val.graphql_name} (#{val.inspect})"
            else
              val.inspect
            end
          else
            val.inspect
          end
        end
      end

      def initialize(query)
        warden_ctx_vals = query.context.to_h.dup
        warden_ctx_vals[:visible_calls] = warden_ctx_vals[:visible_calls].dup
        warden_ctx = GraphQL::Query::Context.new(query: query, values: warden_ctx_vals)
        example_warden = GraphQL::Schema::Warden.new(schema: query.schema, context: warden_ctx)
        @warden_types = example_warden.schema_subset
        warden_ctx.warden = example_warden
        warden_ctx.types = @warden_types
        @subset_types = GraphQL::Schema::Subset.new(query)
      end

      PUBLIC_SUBSET_METHODS = [
        :enum_values,
        :interfaces,
        :all_types,
        :fields,
        :loadable?,
        :type,
        :arguments,
        :argument,
        :directive_exists?,
        :directives,
        :field,
        :query_root,
        :mutation_root,
        :possible_types,
        :subscription_root,
        :loaded_types
      ]

      PUBLIC_SUBSET_METHODS.each do |subset_method|
        define_method(subset_method) do |*args|
          call_method_and_compare(subset_method, args)
        end
      end

      def call_method_and_compare(method, args)
        res_1 = @warden_types.public_send(method, *args)
        res_2 = @subset_types.public_send(method, *args)
        normalized_res_1 = res_1.is_a?(Array) ? Set.new(res_1) : res_1
        normalized_res_2 = res_2.is_a?(Array) ? Set.new(res_2) : res_2
        if normalized_res_1 != normalized_res_2
          # Raise the errors with the orignally returned values:
          err = RuntimeTypesMismatchError.new(method, res_1, res_2, args)
          raise err
        else
          res_2
        end
      end


    end
  end
end
