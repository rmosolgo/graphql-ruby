# Provide a two-step definition process.
#
# 1. Use a config object to gather definitions
# 2. Transfer definitions to an actual instance of an object
#
module GraphQL::DefinitionHelpers::DefinedByConfig
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Pass the block to this class's `DefinitionConfig`,
    # The return the result of {DefinitionConfig#to_instance}
    def define(&block)
      config = self.const_get(:DefinitionConfig).new
      block && config.instance_eval(&block)
      config.to_instance
    end
  end
end
