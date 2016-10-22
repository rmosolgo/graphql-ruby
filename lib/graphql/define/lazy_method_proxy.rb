module GraphQL
  module Define
    # Take a bunch of method definitions and stash them in a module (`eager_method_module`).
    #
    # Then make a dummy module which redefines all those methods (`lazy_method_module`)
    # but with a twist: they're implemented to trigger the defintion block
    # then replace themselves with the _real_ methods (by including the original definitions),
    # then call the real method with the same name.
    module LazyMethodProxy
      def self.create(object, lazy_defn)
        eager_method_module = Module.new
        eager_method_module.class_exec(&lazy_defn)

        lazy_method_module = Module.new {
          eager_method_module.instance_methods.each do |method_name|
            define_method(method_name) do |*args, &block|
              ensure_defined
              # 😱
              self.singleton_class.include(eager_method_module)
              self.public_send(method_name, *args, &block)
            end
          end
        }
        if object.is_a?(Class)
          object.include(lazy_method_module)
        else
          object.singleton_class.include(lazy_method_module)
        end
      end
    end
  end
end
