# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module StrictLoading
        def self.included(child_class)
          child_class.extend(ClassMethods)
        end

        module ClassMethods
          def wrap(object, context)
            if !object.strict_loading?
              object.strict_loading!(mode: :n_plus_one_only)
            end
            super(object, context)
          end

          def scope_items(items, context)
            # if !items.strict_loading_value
            #   items.strict_loading!
            # end
            super
          end
        end
      end
    end
  end
end
