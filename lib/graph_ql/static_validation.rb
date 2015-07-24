module GraphQL::StaticValidation
end

require 'graph_ql/static_validation/message'
require 'graph_ql/static_validation/arguments_validator'
require 'graph_ql/static_validation/type_stack'
require 'graph_ql/static_validation/validator'
require 'graph_ql/static_validation/literal_validator'

rules_glob = File.expand_path("../static_validation/rules/*.rb", __FILE__)
Dir.glob(rules_glob).each do |file|
  require(file)
end

require 'graph_ql/static_validation/all_rules'
