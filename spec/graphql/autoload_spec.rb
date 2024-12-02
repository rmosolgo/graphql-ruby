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
    autoload(:NestedEagerModule, "fixtures/eager_module/nested_eager_module")

    def self.eager_load!
      super

      NestedEagerModule.eager_load!
    end
  end

  describe "#autoload" do
    it "sets autoload" do
      assert LazyModule.const_defined?(:LazyClass)
      assert_equal("fixtures/lazy_module/lazy_class", LazyModule.autoload?(:LazyClass))
      LazyModule::LazyClass
      assert_nil(LazyModule.autoload?(:LazyClass))
    end
  end

  describe "#eager_load!" do
    it "eagerly loads autoload entries" do
      assert EagerModule.autoload?(:EagerClass)
      assert EagerModule.autoload?(:OtherEagerClass)
      assert EagerModule.autoload?(:NestedEagerModule)

      EagerModule.eager_load!

      assert_nil(EagerModule.autoload?(:EagerClass))
      assert_nil(EagerModule.autoload?(:OtherEagerClass))
      assert_nil(EagerModule.autoload?(:NestedEagerModule))
      assert_nil(EagerModule::NestedEagerModule.autoload?(:NestedEagerClass))
      assert EagerModule::NestedEagerModule::NestedEagerClass
    end
  end


  describe "warning in production" do
    before do
      @prev_env = ENV.to_hash
      ENV.update("HANAMI_ENV" => "production")
    end

    after do
      ENV.update(@prev_env)
    end

    it "emits a warning when not eager-loading" do
      stdout, stderr = capture_io do
        GraphQL.ensure_eager_load!
      end

      assert_equal "", stdout
      expected_warning = "GraphQL-Ruby thinks this is a production deployment but didn't eager-load its constants. Address this by:

  - Calling `GraphQL.eager_load!` in a production-only initializer or setup hook
  - Assign `GraphQL.env = \"...\"` to something _other_ than `\"production\"` (for example, `GraphQL.env = \"development\"`)

More details: https://graphql-ruby.org/schema/definition#production-considerations
"
      assert_equal expected_warning, stderr
    end

    it "silences the warning when GraphQL.env is assigned" do
      prev_env = GraphQL.env
      GraphQL.env = "staging"
      stdout, stderr = capture_io do
        GraphQL.ensure_eager_load!
      end
      assert_equal "", stdout
      assert_equal "", stderr
    ensure
      GraphQL.env = prev_env
    end
  end
end
