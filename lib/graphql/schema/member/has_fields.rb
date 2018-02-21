# frozen_string_literal: true
module GraphQL
  class Schema
    module Member
      # Shared code for Object and Interface
      module HasFields
        extend ActiveSupport::Concern

        included do
          class << self
            # Add a field to this object or interface with the given definition
            # @see {GraphQL::Schema::Field#initialize} for method signature
            # @return [void]
            def field(*args, &block)
              field_defn = field_class.new(*args, &block)
              add_field(field_defn)
              nil
            end

            # @return [Hash<String => GraphQL::Schema::Field>] Fields on this object, keyed by name, including inherited fields
            def fields
              inherited_fields = {}
              ancestors[1..-1].reverse.each do |anc|
                if anc < HasFields
                  inherited_fields.merge!(anc.fields)
                end
              end
              # Local overrides take precedence over inherited fields
              inherited_fields.merge(own_fields)
            end

            # Register this field with the class, overriding a previous one if needed
            # @param field_defn [GraphQL::Schema::Field]
            # @return [void]
            def add_field(field_defn)
              own_fields[field_defn.name] = field_defn
              nil
            end

            # @return [Class] The class to initialize when adding fields to this kind of schema member
            def field_class(new_field_class = nil)
              if new_field_class
                @field_class = new_field_class
              elsif @field_class
                @field_class
              else
                ancestors[1..-1].each do |anc|
                  if anc < HasFields
                    return anc.field_class
                  end
                end
                GraphQL::Schema::Field
              end
            end

            private

            # @return [Array<GraphQL::Schema::Field>] Fields defined on this class _specifically_, not parent classes
            def own_fields
              @own_fields ||= {}
            end
          end
        end
      end
    end
  end
end
