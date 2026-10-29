# typed: true
# frozen_string_literal: true

# Subclasses of graphql-ruby's base classes, so Sorbet checks the gem's
# `requires_ancestor` annotations against application classes, too.
module SorbetConsumer
  class BaseArgument < GraphQL::Schema::Argument
  end

  class BaseField < GraphQL::Schema::Field
    argument_class(BaseArgument)
  end

  class BaseDirective < GraphQL::Schema::Directive
    argument_class(BaseArgument)
    locations(FIELD)
  end

  module BaseInterface
    include GraphQL::Schema::Interface
  end

  class BaseObject < GraphQL::Schema::Object
    field_class(BaseField)
  end

  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class(BaseArgument)
  end

  class BaseResolver < GraphQL::Schema::Resolver
    argument_class(BaseArgument)
  end

  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class(BaseArgument)
  end

  class BaseSubscription < GraphQL::Schema::Subscription
    argument_class(BaseArgument)
  end

  class BaseEnum < GraphQL::Schema::Enum
  end

  class BaseScalar < GraphQL::Schema::Scalar
  end

  class BaseUnion < GraphQL::Schema::Union
  end

  module Node
    include BaseInterface
    include GraphQL::Types::Relay::NodeBehaviors
  end

  class Thing < BaseObject
    implements Node
    field :name, String, null: false
  end

  class Query < BaseObject
    include GraphQL::Types::Relay::HasNodeField
    field :things, Thing.connection_type, null: false
  end

  class Schema < GraphQL::Schema
    query(Query)
  end
end
