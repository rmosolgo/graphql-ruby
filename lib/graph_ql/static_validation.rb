module GraphQL::StaticValidation
end

require 'graph_ql/static_validation/message'
require 'graph_ql/static_validation/arguments_validator'
require 'graph_ql/static_validation/type_stack'
require 'graph_ql/static_validation/validator'
require 'graph_ql/static_validation/literal_validator'

rules_glob = File.join(File.dirname(__FILE__), 'static_validation', 'rules') + "/*.rb"
Dir.glob(rules_glob).each do |file|
  require_path = "graph_ql/static_validation/rules/#{File.basename(file, ".rb")}"
  require(require_path)
end

require 'graph_ql/static_validation/all_rules'
