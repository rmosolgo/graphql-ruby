class GraphQL::Config
  @try_underscored_property_names = false
  class << self
    attr_accessor :try_underscored_property_names
  end
end
