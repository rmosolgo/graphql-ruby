# frozen_string_literal: true

module GraphQL
  class Schema
    # This class joins an object type to an abstract type (interface or union) of which
    # it is a member.
    class TypeMembership
      # **Returns**
      #
      # - `Class<GraphQL::Schema::Object>`
      attr_accessor :object_type

      # **Returns**
      #
      # - `Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>`
      attr_reader :abstract_type

      # **Returns**
      #
      # - `Hash`
      attr_reader :options

      # Called when an object is hooked up to an abstract type, such as [Schema::Union.possible_types](rdoc-ref:Schema::Union.possible_types)
      # or [Schema::Object.implements](rdoc-ref:Schema::Object.implements) (for interfaces).
      #
      # **Parameters**
      #
      # - `abstract_type` (`Class<GraphQL::Schema::Union>, Module<GraphQL::Schema::Interface>`)
      # - `object_type` (`Class<GraphQL::Schema::Object>`)
      # - `options` (`Hash`) — Any options passed to `.possible_types` or `.implements`
      def initialize(abstract_type, object_type, **options)
        @abstract_type = abstract_type
        @object_type = object_type
        @options = options
      end

      # **Returns**
      #
      # - `Boolean` — if false, [object type](rdoc-ref:#object_type) will be treated as _not_ a member of [abstract type](rdoc-ref:#abstract_type)
      def visible?(ctx)
        warden = Warden.from_context(ctx)
        (@object_type.respond_to?(:visible?) ? warden.visible_type?(@object_type, ctx) : true) &&
          (@abstract_type.respond_to?(:visible?) ? warden.visible_type?(@abstract_type, ctx) : true)
      end

      def graphql_name
        "#{@object_type.graphql_name}.#{@abstract_type.kind.interface? ? "implements" : "belongsTo" }.#{@abstract_type.graphql_name}"
      end

      def path
        graphql_name
      end

      def inspect
        "#<#{self.class} #{@object_type.inspect} => #{@abstract_type.inspect}>"
      end

      alias :type_class :itself
    end
  end
end
