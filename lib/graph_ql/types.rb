# These objects expose values
module GraphQL::Types
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload(:BooleanType)
    autoload(:DateType)
    autoload(:DateTimeType)
    autoload(:NumberType)
    autoload(:ObjectType)
    autoload(:StringType)
    autoload(:TimeType)
  end
end