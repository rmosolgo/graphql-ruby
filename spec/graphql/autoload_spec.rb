# frozen_string_literal: true

require "spec_helper"

describe GraphQL::Autoload do
  module LazyModule
    extend GraphQL::Autoload
    autoload(:LazyClass, "fixtures/lazy_module/lazy_class")
  end

  module EagerModule
    extend GraphQL::Autoload
    autoload(:EagerClass, "fixtures/eager_module/eager_class")
    autoload(:OtherEagerClass, "fixtures/eager_module/other_eager_class")
  end

  describe "#autoload" do
    it "sets autoload" do
      assert_equal("fixtures/lazy_module/lazy_class", LazyModule.autoload?(:LazyClass))
      LazyModule::LazyClass
      assert_nil(LazyModule.autoload?(:LazyClass))
    end
  end

  describe "#eager_load!" do
    it "eagerly loads autoload entries" do
      EagerModule.eager_load!

      assert_nil(EagerModule.autoload?(:EagerClass))
      assert_nil(EagerModule.autoload?(:OtherEagerClass))
    end
  end
end
