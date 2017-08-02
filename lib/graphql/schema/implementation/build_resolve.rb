# frozen_string_literal: true
# test_via: spec/graphql/schema/implementation_spec.rb
module GraphQL
  class Schema
    class Implementation
      # TODO, can users extend this, provide custom args?
      SPECIAL_ARGS = Set.new([
        :irep_node,
        :ast_node,
      ])

      module BuildResolve
        def self.build(impl_class, field)
          field_name = field.name
          field_args = field.arguments
          # Remove camelization
          method_name = field_name
            .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')
            .downcase

          if impl_class.method_defined?(method_name)
            field_method = impl_class.instance_method(method_name)
            graphql_args = []
            special_args = []
            field_method.parameters.each do |(type, name)|
              case type
              when :req, :opt
                raise InvalidImplementationError.new(
                  "positional arguments are not supported (use a keyword argument instead), see #{impl_class.name}##{method_name} (#{field_method.source_location.join(":")})"
                )
              when :key
                raise InvalidImplementationError.new(
                  "unexpected default value for #{name.inspect} (remove the Ruby default, one will be provided by GraphQL), see #{impl_class.name}##{method_name} (#{field_method.source_location.join(":")})"
                )
              when :keyreq
                arg_name = name.to_s
                if field_args.key?(arg_name)
                  graphql_args << name
                elsif SPECIAL_ARGS.include?(name)
                  special_args << name
                else
                  raise InvalidImplementationError.new(
                    "unexpected keyword #{name.inspect}, see #{impl_class.name}##{method_name} (#{field_method.source_location.join(":")})"
                  )
                end
              end
            end

            Implementation::MethodCallImplementation.new(
              method: method_name,
              graphql_arguments: graphql_args,
              special_arguments: special_args,
            )
          else
            Implementation::PublicSendImplementation.new(method: method_name)
          end
        end
      end
    end
  end
end
