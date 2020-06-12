# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasUnresolvedTypeError do
  it "adds error classes to interfaces and unions" do
    assert_equal Jazz::NamedEntity::UnresolvedTypeError.superclass, GraphQL::UnresolvedTypeError
    assert_equal Jazz::PerformingAct::UnresolvedTypeError.superclass, GraphQL::UnresolvedTypeError
    assert Jazz::NamedEntity.const_defined?(:UnresolvedTypeError, false)
    assert Jazz::PerformingAct.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Musician.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Family.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::Key.const_defined?(:UnresolvedTypeError, false)
    refute Jazz::InspectableInput.const_defined?(:UnresolvedTypeError, false)
  end
end
