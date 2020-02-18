# frozen_string_literal: true
module GraphQL
  class Schema
    # Visit the members of this schema and build up artifacts for runtime.
    # @api private
    class Traversal
      # @return [Hash<String => GraphQL::BaseType]
      attr_reader :type_map

      # @return [Hash<String => Hash<String => GraphQL::Field>>]
      attr_reader :instrumented_field_map

      # @return [Hash<String => Array<GraphQL::Field || GraphQL::Argument || GraphQL::Directive>]
      attr_reader :type_reference_map

      # @return [Hash<String => Array<GraphQL::BaseType>]
      attr_reader :union_memberships


      # @param schema [GraphQL::Schema]
      def initialize(schema, introspection: true)
        @schema = schema
        @introspection = introspection
        built_in_insts = [
          GraphQL::Relay::ConnectionInstrumentation,
          GraphQL::Relay::EdgesInstrumentation,
          GraphQL::Relay::Mutation::Instrumentation,
        ]

        if schema.query_execution_strategy != GraphQL::Execution::Interpreter
          built_in_insts << GraphQL::Schema::Member::Instrumentation
        end

        @field_instrumenters =
          schema.instrumenters[:field] +
            built_in_insts +
            schema.instrumenters[:field_after_built_ins]

        # These fields have types specified by _name_,
        # So we need to inspect the schema and find those types,
        # then update their references.
        @late_bound_fields = []
        @type_map = {}
        @instrumented_field_map = Hash.new { |h, k| h[k] = {} }
        @type_reference_map = Hash.new { |h, k| h[k] = [] }
        @union_memberships = Hash.new { |h, k| h[k] = [] }
        visit(schema, schema, nil)
        resolve_late_bound_fields
      end

      private

      # A brute-force appraoch to late binding.
      # Just keep trying the whole list, hoping that they
      # eventually all resolve.
      # This could be replaced with proper dependency tracking.
      def resolve_late_bound_fields
        # This is a bit tricky, with the writes going to internal state.
        prev_late_bound_fields = @late_bound_fields
        # Things might get added here during `visit...`
        # or they might be added manually if we can't find them by hand
        @late_bound_fields = []
        prev_late_bound_fields.each do |(owner_type, field_defn, dynamic_field)|
          if @type_map.key?(field_defn.type.unwrap.name)
            late_bound_return_type = field_defn.type
            resolved_type = @type_map.fetch(late_bound_return_type.unwrap.name)
            wrapped_resolved_type = rewrap_resolved_type(late_bound_return_type, resolved_type)
            # Update the field definition in place? :thinking_face:
            field_defn.type = wrapped_resolved_type
            visit_field_on_type(@schema, owner_type, field_defn, dynamic_field: dynamic_field)
          else
            @late_bound_fields << [owner_type, field_defn, dynamic_field]
          end
        end

        if @late_bound_fields.any?
          # If we visited each field and failed to resolve _any_,
          # then we're stuck.
          if @late_bound_fields == prev_late_bound_fields
            type_names = prev_late_bound_fields.map { |f| f[1] }.map(&:type).map(&:unwrap).map(&:name).uniq
            raise <<-ERR
Some late-bound types couldn't be resolved:

- #{type_names}
- Found __* types: #{@type_map.keys.select { |k| k.start_with?("__") }}
            ERR
          else
            resolve_late_bound_fields
          end
        end
      end

      # The late-bound type may be wrapped with list or non-null types.
      # Apply the same wrapping to the resolve type and
      # return the maybe-wrapped type
      def rewrap_resolved_type(late_bound_type, resolved_inner_type)
        case late_bound_type
        when GraphQL::NonNullType
          rewrap_resolved_type(late_bound_type.of_type, resolved_inner_type).to_non_null_type
        when GraphQL::ListType
          rewrap_resolved_type(late_bound_type.of_type, resolved_inner_type).to_list_type
        when GraphQL::Schema::LateBoundType
          resolved_inner_type
        else
          raise "Unexpected late_bound_type: #{late_bound_type.inspect} (#{late_bound_type.class})"
        end
      end

      def visit(schema, member, context_description)
        case member
        when GraphQL::Schema
          member.directives.each { |name, directive| visit(schema, directive, "Directive #{name}") }
          # Find the starting points, then visit them
          visit_roots = [member.query, member.mutation, member.subscription]
          if @introspection
            introspection_types = schema.introspection_system.types.values
            visit_roots.concat(introspection_types)
            if member.query
              member.introspection_system.entry_points.each do |introspection_field|
                # Visit this so that arguments class is preconstructed
                # Skip validation since it begins with "__"
                visit_field_on_type(schema, member.query, introspection_field, dynamic_field: true)
              end
            end
          end
          visit_roots.concat(member.orphan_types)
          visit_roots.compact!
          visit_roots.each { |t| visit(schema, t, t.name) }
        when GraphQL::Directive
          member.arguments.each do |name, argument|
            @type_reference_map[argument.type.unwrap.to_s] << argument
            visit(schema, argument.type, "Directive argument #{member.name}.#{name}")
          end
          # Construct arguments class here, which is later used to generate GraphQL::Query::Arguments
          # to be passed to a resolver proc
          GraphQL::Query::Arguments.construct_arguments_class(member)
        when GraphQL::BaseType
          type_defn = member.unwrap
          prev_type = @type_map[type_defn.name]
          # Continue to visit this type if it's the first time we've seen it:
          if prev_type.nil?
            validate_type(type_defn, context_description)
            @type_map[type_defn.name] = type_defn
            case type_defn
            when GraphQL::ObjectType
              type_defn.interfaces.each { |i| visit(schema, i, "Interface on #{type_defn.name}") }
              visit_fields(schema, type_defn)
            when GraphQL::InterfaceType
              visit_fields(schema, type_defn)
              type_defn.orphan_types.each do |t|
                visit(schema, t, "Orphan type for #{type_defn.name}")
              end
            when GraphQL::UnionType
              type_defn.possible_types.each do |t|
                @union_memberships[t.name] << type_defn
                visit(schema, t, "Possible type for #{type_defn.name}")
              end
            when GraphQL::InputObjectType
              type_defn.arguments.each do |name, arg|
                @type_reference_map[arg.type.unwrap.to_s] << arg
                visit(schema, arg.type, "Input field #{type_defn.name}.#{name}")
              end

              # Construct arguments class here, which is later used to generate GraphQL::Query::Arguments
              # to be passed to a resolver proc
              if type_defn.arguments_class.nil?
                GraphQL::Query::Arguments.construct_arguments_class(type_defn)
              end
            end
          elsif !prev_type.equal?(type_defn)
            # If the previous entry in the map isn't the same object we just found, raise.
            raise("Duplicate type definition found for name '#{type_defn.name}' at '#{context_description}' (#{prev_type.metadata[:type_class] || prev_type}, #{type_defn.metadata[:type_class] || type_defn})")
          end
        when Class
          if member.respond_to?(:graphql_definition)
            graphql_member = member.graphql_definition
            visit(schema, graphql_member, context_description)
          else
            raise GraphQL::Schema::InvalidTypeError.new("Unexpected traversal member: #{member} (#{member.class.name})")
          end
        else
          message = "Unexpected schema traversal member: #{member} (#{member.class.name})"
          raise GraphQL::Schema::InvalidTypeError.new(message)
        end
      end

      def visit_fields(schema, type_defn)
        type_defn.all_fields.each do |field_defn|
          visit_field_on_type(schema, type_defn, field_defn)
        end
      end

      def visit_field_on_type(schema, type_defn, field_defn, dynamic_field: false)
        base_return_type = field_defn.type.unwrap
        if base_return_type.is_a?(GraphQL::Schema::LateBoundType)
          @late_bound_fields << [type_defn, field_defn, dynamic_field]
          return
        end
        if dynamic_field
          # Don't apply instrumentation to dynamic fields since they're shared constants
          instrumented_field_defn = field_defn
        else
          instrumented_field_defn = @field_instrumenters.reduce(field_defn) do |defn, inst|
            inst.instrument(type_defn, defn)
          end
          @instrumented_field_map[type_defn.name][instrumented_field_defn.name] = instrumented_field_defn
        end
        @type_reference_map[instrumented_field_defn.type.unwrap.name] << instrumented_field_defn
        visit(schema, instrumented_field_defn.type, "Field #{type_defn.name}.#{instrumented_field_defn.name}'s return type")
        instrumented_field_defn.arguments.each do |name, arg|
          @type_reference_map[arg.type.unwrap.to_s] << arg
          visit(schema, arg.type, "Argument #{name} on #{type_defn.name}.#{instrumented_field_defn.name}")
        end

        # Construct arguments class here, which is later used to generate GraphQL::Query::Arguments
        # to be passed to a resolver proc
        GraphQL::Query::Arguments.construct_arguments_class(instrumented_field_defn)
      end

      def validate_type(member, context_description)
        error_message = GraphQL::Schema::Validation.validate(member)
        if error_message
          raise GraphQL::Schema::InvalidTypeError.new("#{context_description} is invalid: #{error_message}")
        end
      end
    end
  end
end
