
if ActiveSupport::Inflector.method(:inflections).arity == 0
  # Rails 3 does not take a language in inflections.
  ActiveSupport::Inflector.inflections do |inflect|
    inflect.acronym("GraphQL")
    inflect.acronym("IDE")
  end
else
  ActiveSupport::Inflector.inflections(:en) do |inflect|
    inflect.acronym("GraphQL")
    inflect.acronym("IDE")
  end
end

require_relative "./lib/ide/engine"
require_relative './lib/parameters'
