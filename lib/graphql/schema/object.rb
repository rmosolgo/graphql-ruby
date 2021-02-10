# frozen_string_literal: true

require "graphql/query/null_context"

module GraphQL
  class Schema
    class Object < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::HasFields

      # @return [Object] the application object this type is wrapping
      attr_reader :object

      # @return [GraphQL::Query::Context] the context instance for this query
      attr_reader :context

      # @return [GraphQL::Dataloader]
      def dataloader
        context.dataloader
      end

      # Call this in a field method to return a value that should be returned to the client
      # without any further handling by GraphQL.
      def raw_value(obj)
        GraphQL::Execution::Interpreter::RawValue.new(obj)
      end

      class << self
        # This is protected so that we can be sure callers use the public method, {.authorized_new}
        # @see authorized_new to make instances
        protected :new

        # Make a new instance of this type _if_ the auth check passes,
        # otherwise, raise an error.
        #
        # Probably only the framework should call this method.
        #
        # This might return a {GraphQL::Execution::Lazy} if the user-provided `.authorized?`
        # hook returns some lazy value (like a Promise).
        #
        # The reason that the auth check is in this wrapper method instead of {.new} is because
        # of how it might return a Promise. It would be weird if `.new` returned a promise;
        # It would be a headache to try to maintain Promise-y state inside a {Schema::Object}
        # instance. So, hopefully this wrapper method will do the job.
        #
        # @param object [Object] The thing wrapped by this object
        # @param context [GraphQL::Query::Context]
        # @return [GraphQL::Schema::Object, GraphQL::Execution::Lazy]
        # @raise [GraphQL::UnauthorizedError] if the user-provided hook returns `false`
        def authorized_new(object, context)
          auth_val = context.query.with_error_handling do
            begin
              authorized?(object, context)
            rescue GraphQL::UnauthorizedError => err
              context.schema.unauthorized_object(err)
            end
          end

          context.schema.after_lazy(auth_val) do |is_authorized|
            if is_authorized
              self.new(object, context)
            else
              # It failed the authorization check, so go to the schema's authorized object hook
              err = GraphQL::UnauthorizedError.new(object: object, type: self, context: context)
              # If a new value was returned, wrap that instead of the original value
              begin
                new_obj = context.schema.unauthorized_object(err)
                if new_obj
                  self.new(new_obj, context)
                else
                  nil
                end
              end
            end
          end
        end
      end

      def initialize(object, context)
        @object = object
        @context = context
      end

      class << self
        # Set up a type-specific invalid null error to use when this object's non-null fields wrongly return `nil`.
        # It should help with debugging and bug tracker integrations.
        def inherited(child_class)
          child_class.const_set(:InvalidNullError, GraphQL::InvalidNullError.subclass_for(child_class))
          super
        end

        def implements(*new_interfaces, **options)
          new_memberships = []
          new_interfaces.each do |int|
            if int.is_a?(Module)
              unless int.include?(GraphQL::Schema::Interface)
                raise "#{int} cannot be implemented since it's not a GraphQL Interface. Use `include` for plain Ruby modules."
              end

              new_memberships << int.type_membership_class.new(int, self, **options)

              # Include the methods here,
              # `.fields` will use the inheritance chain
              # to find inherited fields
              include(int)
            elsif int.is_a?(GraphQL::InterfaceType)
              new_memberships << int.type_membership_class.new(int, self, **options)
            elsif int.is_a?(String) || int.is_a?(GraphQL::Schema::LateBoundType)
              if options.any?
                raise ArgumentError, "`implements(...)` doesn't support options with late-loaded types yet. Remove #{options} and open an issue to request this feature."
              end
              new_memberships << int
            else
              raise ArgumentError, "Unexpected interface definition (expected module): #{int} (#{int.class})"
            end
          end

          # Remove any interfaces which are being replaced (late-bound types are updated in place this way)
          own_interface_type_memberships.reject! { |old_i_m|
            old_int_type = old_i_m.respond_to?(:abstract_type) ? old_i_m.abstract_type : old_i_m
            old_name = Schema::Member::BuildType.to_type_name(old_int_type)

            new_memberships.any? { |new_i_m|
              new_int_type = new_i_m.respond_to?(:abstract_type) ? new_i_m.abstract_type : new_i_m
              new_name = Schema::Member::BuildType.to_type_name(new_int_type)

              new_name == old_name
            }
          }
          own_interface_type_memberships.concat(new_memberships)
        end

        def own_interface_type_memberships
          @own_interface_type_memberships ||= []
        end

        def interface_type_memberships
          own_interface_type_memberships + (superclass.respond_to?(:interface_type_memberships) ? superclass.interface_type_memberships : [])
        end

        # param context [Query::Context] If omitted, skip filtering.
        def interfaces(context = GraphQL::Query::NullContext)
          visible_interfaces = []
          unfiltered = context == GraphQL::Query::NullContext
          own_interface_type_memberships.each do |type_membership|
            # During initialization, `type_memberships` can hold late-bound types
            case type_membership
            when String, Schema::LateBoundType
              visible_interfaces << type_membership
            when Schema::TypeMembership
              if unfiltered || type_membership.visible?(context)
                visible_interfaces << type_membership.abstract_type
              end
            else
              raise "Invariant: Unexpected type_membership #{type_membership.class}: #{type_membership.inspect}"
            end
          end
          visible_interfaces + (superclass <= GraphQL::Schema::Object ? superclass.interfaces(context) : [])
        end

        # @return [Hash<String => GraphQL::Schema::Field>] All of this object's fields, indexed by name
        # @see get_field A faster way to find one field by name ({#fields} merges hashes of inherited fields; {#get_field} just looks up one field.)
        def fields
          all_fields = super
          interfaces.each do |int|
            # Include legacy-style interfaces, too
            if int.is_a?(GraphQL::InterfaceType)
              int_f = {}
              int.fields.each do |name, legacy_field|
                int_f[name] = field_class.from_options(name, field: legacy_field)
              end
              all_fields = int_f.merge(all_fields)
            end
          end
          all_fields
        end

        # @return [GraphQL::ObjectType]
        def to_graphql
          obj_type = GraphQL::ObjectType.new
          obj_type.name = graphql_name
          obj_type.description = description
          obj_type.structural_interface_type_memberships = interface_type_memberships
          obj_type.introspection = introspection
          obj_type.mutation = mutation
          obj_type.ast_node = ast_node
          fields.each do |field_name, field_inst|
            field_defn = field_inst.to_graphql
            obj_type.fields[field_defn.name] = field_defn
          end

          obj_type.metadata[:type_class] = self

          obj_type
        end

        def kind
          GraphQL::TypeKinds::OBJECT
        end
      end
    end
  end
end
