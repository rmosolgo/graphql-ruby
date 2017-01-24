# frozen_string_literal: true
require "graphql/static_validation/message"
require "graphql/static_validation/arguments_validator"
require "graphql/static_validation/definition_dependencies"
require "graphql/static_validation/type_stack"
require "graphql/static_validation/validator"
require "graphql/static_validation/validation_context"
require "graphql/static_validation/literal_validator"


rules_glob = File.expand_path("../static_validation/rules/*.rb", __FILE__)
Dir.glob(rules_glob).each do |file|
  require(file)
end

require "graphql/static_validation/all_rules"
