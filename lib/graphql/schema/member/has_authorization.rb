# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasAuthorization
        def self.included(child_class)
          child_class.include(InstanceConfigured)
        end

        def self.extended(child_class)
          child_class.extend(ClassConfigured)
          child_class.class_exec do
            @authorizes = false
          end
        end

        def authorized?(object, context)
          true
        end

        module InstanceConfigured
          def authorizes?(context)
            raise RequiredImplementationMissingError, "#{self.class} must implement #authorizes?(context)"
          end
        end

        module ClassConfigured
          def authorizes?(context)
            method(:authorized?).owner != GraphQL::Schema::Member::HasAuthorization
          end
        end
      end
    end
  end
end
