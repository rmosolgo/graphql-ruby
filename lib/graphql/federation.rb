# frozen_string_literal: true

require "delegate"
require "graphql"

module GraphQL
  module Federation
    class Any < GraphQL::Schema::Scalar
      graphql_name "_Any"
      description "Represents arbitrary entity representations for GraphQL federation."

      def self.coerce_input(value, _context)
        value
      end

      def self.coerce_result(value, _context)
        value
      end
    end

    class FieldSet < GraphQL::Schema::Scalar
      graphql_name "_FieldSet"
      description "Represents a federation field set selection."

      def self.coerce_input(value, _context)
        value
      end

      def self.coerce_result(value, _context)
        value
      end
    end

    class EntityObject < SimpleDelegator
      attr_reader :graphql_type, :object

      def initialize(graphql_type, object)
        @graphql_type = graphql_type
        @object = object
        super(object)
      end

      def respond_to_missing?(method_name, include_private = false)
        super ||
          (object.is_a?(Hash) && (object.key?(method_name) || object.key?(method_name.to_s))) ||
          object.respond_to?(method_name, include_private)
      end

      def method_missing(method_name, *args, &block)
        if args.empty? && object.is_a?(Hash)
          if object.key?(method_name)
            return object[method_name]
          elsif object.key?(method_name.to_s)
            return object[method_name.to_s]
          end
        end

        super
      end
    end

    class Service < GraphQL::Schema::Object
      graphql_name "_Service"
      description "Federation service metadata for this subgraph."

      field :sdl, String, null: false
    end

    class ServiceValue
      def initialize(schema)
        @schema = schema
      end

      def sdl
        @schema.federation_sdl
      end
    end

    module ObjectHelpers
      def key(fields, resolvable: true)
        directive(GraphQL::Federation::Directives::Key, fields: fields, resolvable: resolvable)
      end

      alias federation_key key

      def federation_extends
        directive(GraphQL::Federation::Directives::Extends)
      end

      def shareable
        directive(GraphQL::Federation::Directives::Shareable)
      end

      def inaccessible
        directive(GraphQL::Federation::Directives::Inaccessible)
      end

      def interface_object
        directive(GraphQL::Federation::Directives::InterfaceObject)
      end

      def tag(name)
        directive(GraphQL::Federation::Directives::Tag, name: name)
      end
    end

    module FieldHelpers
      def external
        directive(GraphQL::Federation::Directives::External)
      end

      def requires(fields)
        directive(GraphQL::Federation::Directives::Requires, fields: fields)
      end

      def provides(fields)
        directive(GraphQL::Federation::Directives::Provides, fields: fields)
      end

      def shareable
        directive(GraphQL::Federation::Directives::Shareable)
      end

      def inaccessible
        directive(GraphQL::Federation::Directives::Inaccessible)
      end

      def override_from(subgraph, label: nil)
        options = { from: subgraph }
        options[:label] = label if label
        directive(GraphQL::Federation::Directives::Override, **options)
      end

      def tag(name)
        directive(GraphQL::Federation::Directives::Tag, name: name)
      end
    end

    module SchemaMethods
      def federation_entity_type
        @federation_entity_type
      end

      def federation_entity_types(context = null_context)
        types(context).values.select { |type| GraphQL::Federation.entity_type?(type) }
      end

      def federation_resolve_entities(representations, context)
        representations.map do |representation|
          GraphQL::Federation.resolve_entity(self, representation, context)
        end
      end

      def federation_sdl(context: {})
        GraphQL::Federation.sdl(self, context: context)
      end
    end

    class << self
      FEDERATION_TYPE_NAMES = ["_Any", "_Entity", "_FieldSet", "_Service"].freeze
      FEDERATION_FIELD_NAMES = ["_entities", "_service"].freeze

      def use(schema, **_options)
        install!
        schema.extend(SchemaMethods)
        register_directives(schema)
        install_root_fields(schema)
        nil
      end

      def install!
        return if @installed

        GraphQL::Schema::Object.extend(ObjectHelpers)
        GraphQL::Schema::Interface::DefinitionMethods.include(ObjectHelpers)
        GraphQL::Schema::Field.include(FieldHelpers)
        @installed = true
      end

      def entity_type?(type)
        type.is_a?(Class) &&
          type < GraphQL::Schema::Object &&
          type.respond_to?(:directives) &&
          type.directives.any? { |dir| dir.is_a?(GraphQL::Federation::Directives::Key) && dir.arguments[:resolvable] }
      end

      def resolve_entity(schema, representation, context)
        type_name = representation["__typename"] || representation[:__typename]
        type = type_name && schema.get_type(type_name, context)

        return nil unless entity_type?(type)

        object = if type.respond_to?(:resolve_reference)
          call_resolve_reference(type, representation, context)
        else
          representation
        end

        if schema.lazy?(object)
          context.query.after_lazy(object) { |resolved_object| wrap_entity(type, resolved_object) }
        else
          wrap_entity(type, object)
        end
      end

      def sdl(schema, context: {})
        document = GraphQL::Language::DocumentFromSchemaDefinition.new(schema, context: context).document
        query_type_name = schema.query&.graphql_name
        definitions = document.definitions.filter_map do |definition|
          if definition.is_a?(GraphQL::Language::Nodes::DirectiveDefinition) && federation_directive_names.include?(definition.name)
            next
          elsif definition.respond_to?(:name) && FEDERATION_TYPE_NAMES.include?(definition.name)
            next
          elsif definition.is_a?(GraphQL::Language::Nodes::ObjectTypeDefinition) && definition.name == query_type_name
            fields = definition.fields.reject { |field| FEDERATION_FIELD_NAMES.include?(field.name) }
            definition = definition.merge(fields: fields)
          end

          definition
        end

        document.merge(definitions: definitions).to_query_string + "\n"
      end

      private

      def wrap_entity(type, object)
        object.nil? ? nil : EntityObject.new(type, object)
      end

      def register_directives(schema)
        GraphQL::Federation::Directives::ALL.each do |directive|
          schema.directive(directive)
        end
      end

      def federation_directive_names
        @federation_directive_names ||= GraphQL::Federation::Directives::ALL.map(&:graphql_name).freeze
      end

      def install_root_fields(schema)
        query_type = schema.query
        raise ArgumentError, "GraphQL::Federation requires a query root before `use GraphQL::Federation`." unless query_type

        install_service_field(schema, query_type)

        entity_types = schema.federation_entity_types
        if !entity_types.empty?
          entity_type = build_entity_union(schema, entity_types)
          schema.instance_variable_set(:@federation_entity_type, entity_type)
          install_entities_field(schema, query_type, entity_type)
          schema.send(:add_type_and_traverse, [Any, FieldSet, Service, entity_type], root: false)
        else
          schema.send(:add_type_and_traverse, [Any, FieldSet, Service], root: false)
        end
      end

      def install_service_field(_schema, query_type)
        return if query_type.get_field("_service")

        query_type.field :_service,
          Service,
          null: false,
          camelize: false,
          method_conflict_warning: false,
          resolver_method: :__graphql_federation_service

        query_type.define_method(:__graphql_federation_service) do
          GraphQL::Federation::ServiceValue.new(context.schema)
        end
      end

      def install_entities_field(_schema, query_type, entity_type)
        return if query_type.get_field("_entities")

        query_type.field :_entities,
          [entity_type, null: true],
          null: false,
          camelize: false,
          method_conflict_warning: false,
          resolver_method: :__graphql_federation_entities do
            argument :representations, [GraphQL::Federation::Any, null: false], required: true
          end

        query_type.define_method(:__graphql_federation_entities) do |representations:|
          context.schema.federation_resolve_entities(representations, context)
        end
      end

      def build_entity_union(_schema, entity_types)
        Class.new(GraphQL::Schema::Union) do
          graphql_name "_Entity"
          description "Federation entity types resolvable by this subgraph."
          possible_types(*entity_types)

          def self.resolve_type(object, _context)
            object.graphql_type
          end
        end
      end

      def call_resolve_reference(type, representation, context)
        method = type.method(:resolve_reference)
        parameters = method.parameters

        if parameters.any? { |kind, name| (kind == :keyreq || kind == :key) && name == :context }
          method.call(representation, context: context)
        elsif parameters.count { |kind, _name| kind == :req || kind == :opt } >= 2
          method.call(representation, context)
        else
          method.call(representation)
        end
      end
    end
  end
end

require "graphql/federation/directives"
GraphQL::Federation.install!
