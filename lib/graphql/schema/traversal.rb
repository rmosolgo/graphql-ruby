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
        @field_instrumenters =
          schema.instrumenters[:field] +
            Schema::BUILT_IN_INSTRUMENTERS +
            schema.instrumenters[:field_after_built_ins]

        @type_map = {}
        @instrumented_field_map = Hash.new { |h, k| h[k] = {} }
        @type_reference_map = Hash.new { |h, k| h[k] = [] }
        @union_memberships = Hash.new { |h, k| h[k] = [] }
        visit(schema, nil)
      end

      private

      def visit(member, context_description)
        case member
        when GraphQL::Schema
          member.directives.each { |name, directive| visit(directive, "Directive #{name}") }
          # Find the starting points, then visit them
          visit_roots = [member.query, member.mutation, member.subscription]
          if @introspection
            visit_roots << GraphQL::Introspection::SchemaType
          end
          visit_roots.concat(member.orphan_types)
          visit_roots.compact!
          visit_roots.each { |t| visit(t, t.name) }
        when GraphQL::Directive
          member.arguments.each do |name, argument|
            @type_reference_map[argument.type.unwrap.to_s] << argument
            visit(argument.type, "Directive argument #{member.name}.#{name}")
          end
        when GraphQL::BaseType
          type_defn = member.unwrap
          prev_type = @type_map[type_defn.name]
          # Continue to visit this type if it's the first time we've seen it:
          if prev_type.nil?
            validate_type(type_defn, context_description)
            @type_map[type_defn.name] = type_defn
            case type_defn
            when GraphQL::ObjectType
              type_defn.interfaces.each { |i| visit(i, "Interface on #{type_defn.name}") }
              visit_fields(type_defn)
            when GraphQL::InterfaceType
              visit_fields(type_defn)
            when GraphQL::UnionType
              type_defn.possible_types.each do |t|
                @union_memberships[t.name] << type_defn
                visit(t, "Possible type for #{type_defn.name}")
              end
            when GraphQL::InputObjectType
              type_defn.arguments.each do |name, arg|
                @type_reference_map[arg.type.unwrap.to_s] << arg
                visit(arg.type, "Input field #{type_defn.name}.#{name}")
              end
            end
          elsif !prev_type.equal?(type_defn)
            # If the previous entry in the map isn't the same object we just found, raise.
            raise("Duplicate type definition found for name '#{type_defn.name}'")
          end
        else
          message = "Unexpected schema traversal member: #{member} (#{member.class.name})"
          raise GraphQL::Schema::InvalidTypeError.new(message)
        end
      end

      def visit_fields(type_defn)
        type_defn.all_fields.each do |field_defn|
          instrumented_field_defn = @field_instrumenters.reduce(field_defn) do |defn, inst|
            inst.instrument(type_defn, defn)
          end
          @instrumented_field_map[type_defn.name][instrumented_field_defn.name] = instrumented_field_defn
          @type_reference_map[instrumented_field_defn.type.unwrap.name] << instrumented_field_defn
          visit(instrumented_field_defn.type, "Field #{type_defn.name}.#{instrumented_field_defn.name}'s return type")
          instrumented_field_defn.arguments.each do |name, arg|
            @type_reference_map[arg.type.unwrap.to_s] << arg
            visit(arg.type, "Argument #{name} on #{type_defn.name}.#{instrumented_field_defn.name}")
          end
        end
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
