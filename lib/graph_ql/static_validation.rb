module GraphQL::StaticValidation
end

require 'graph_ql/static_validation/message'

require 'graph_ql/static_validation/directives_are_defined'
require 'graph_ql/static_validation/fields_are_defined_on_type'
require 'graph_ql/static_validation/fields_have_appropriate_selections'
require 'graph_ql/static_validation/fields_will_merge'
require 'graph_ql/static_validation/fragments_are_used'
require 'graph_ql/static_validation/type_stack'
require 'graph_ql/static_validation/validator'
