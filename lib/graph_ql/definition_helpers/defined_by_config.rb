module GraphQL::DefinitionHelpers::DefinedByConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def define(&block)
      config = self.const_get(:DefinitionConfig).new
      block && config.instance_eval(&block)
      config.to_instance
    end
  end
end
