# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasInterfaces
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

              # If this interface has interfaces of its own, add those, too
              int.interfaces.each do |next_interface|
                implements(next_interface)
              end
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

          # Remove any String or late-bound interfaces which are being replaced
          own_interface_type_memberships.reject! { |old_i_m|
            if !(old_i_m.respond_to?(:abstract_type) && old_i_m.abstract_type.is_a?(Module))
              old_int_type = old_i_m.respond_to?(:abstract_type) ? old_i_m.abstract_type : old_i_m
              old_name = Schema::Member::BuildType.to_type_name(old_int_type)

              new_memberships.any? { |new_i_m|
                new_int_type = new_i_m.respond_to?(:abstract_type) ? new_i_m.abstract_type : new_i_m
                new_name = Schema::Member::BuildType.to_type_name(new_int_type)

                new_name == old_name
              }
            end
          }
          own_interface_type_memberships.concat(new_memberships)
        end

        def own_interface_type_memberships
          @own_interface_type_memberships ||= []
        end

        def interface_type_memberships
          own_tms = own_interface_type_memberships
          if (self.is_a?(Class) && superclass.respond_to?(:interface_type_memberships))
            inherited_tms = superclass.interface_type_memberships
            if inherited_tms.size > 0
              own_tms + inherited_tms
            else
              own_tms
            end
          else
            own_tms
          end
        end

        # param context [Query::Context] If omitted, skip filtering.
        def interfaces(context = GraphQL::Query::NullContext)
          warden = Warden.from_context(context)
          visible_interfaces = []
          own_interface_type_memberships.each do |type_membership|
            # During initialization, `type_memberships` can hold late-bound types
            case type_membership
            when String, Schema::LateBoundType
              visible_interfaces << type_membership
            when Schema::TypeMembership
              if warden.visible_type_membership?(type_membership, context)
                visible_interfaces << type_membership.abstract_type
              end
            else
              raise "Invariant: Unexpected type_membership #{type_membership.class}: #{type_membership.inspect}"
            end
          end

          if self.is_a?(Class) && superclass <= GraphQL::Schema::Object
            visible_interfaces.concat(superclass.interfaces(context))
          end

          visible_interfaces
        end
      end
    end
  end
end
