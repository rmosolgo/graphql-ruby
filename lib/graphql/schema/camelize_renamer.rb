module GraphQL
  class Schema
    module CamelizeRenamer
      def self.rename_field(field)
        defined_as = field.name
        camelized = ActiveSupport::Inflector.camelize(defined_as, false)

        if field.resolve_proc.is_a?(GraphQL::Field::Resolve::NameResolve)
          field.redefine(name: camelized, property: defined_as.to_sym)
        else
          field.redefine(name: camelized)
        end
      end

      def self.rename_argument(argument)
        defined_as = argument.name
        camelized = ActiveSupport::Inflector.camelize(defined_as, false)

        if argument.as
          argument.redefine(name: camelized)
        else
          argument.redefine(name: camelized, as: defined_as)
        end
      end
    end
  end
end
