module GraphQL
  module IDE
    class Engine < ::Rails::Engine
      isolate_namespace GraphQL::IDE
    end
  end
end
