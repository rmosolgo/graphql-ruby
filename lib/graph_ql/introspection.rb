# These objects are used for introspections (eg, responding to `schema()` calls).
module GraphQL::Introspection
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload(:CallType)
    autoload(:Connection)
    autoload(:FieldType)
    autoload(:RootCallArgumentNode)
    autoload(:RootCallType)
    autoload(:SchemaCall)
    autoload(:SchemaType)
    autoload(:TypeCall)
    autoload(:TypeType)
  end
end