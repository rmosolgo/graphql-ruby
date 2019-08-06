module GraphQL
  class Schema
    module FindInheritedValue
      private

      def find_inherited_value(method_name, default_value = nil)
        if self.is_a?(Class)
          superclass.respond_to?(method_name, true) ? superclass.send(method_name) : default_value
        else
          ancestors[1..-1].each do |ancestor|
            if ancestor.respond_to?(method_name, true)
              return ancestor.send(method_name)
            end
          end
          default_value
        end
      end
    end
  end
end
