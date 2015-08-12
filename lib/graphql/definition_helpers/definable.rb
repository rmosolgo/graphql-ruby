# Define attributes which can be assigned & read, or
# "defined", by passing the new value as an argument
#
# @example defining an object's name
#   object.name("New name")
#
module GraphQL::DefinitionHelpers::Definable
  def attr_definable(*names)
    attr_accessor(*names)
    names.each do |name|
      ivar_name = "@#{name}".to_sym
      define_method(name) do |new_value=nil|
        new_value && self.instance_variable_set(ivar_name, new_value)
        instance_variable_get(ivar_name)
      end
    end
  end
end
