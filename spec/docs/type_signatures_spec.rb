# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../tool/docs/type_signatures"

describe GraphQLDocs::TypeSignatureMigrator do
  it "converts migrated YARD type sections into RDoc call sequences" do
    source = <<~RUBY
      class Example
        # Does something.
        #
        # **Parameters**
        #
        # - `value` (`String`)
        #
        # **Returns**
        #
        # - `Array<String>`
        def call(value)
          [value]
        end
      end
    RUBY

    result = GraphQLDocs::TypeSignatureMigrator.new(paths: []).migrate(source)

    _(result).must_include("# :call-seq:")
    _(result).must_include("#   call(String value) -> Array[String]")
    _(result).must_include("def call(value)")
  end

  it "keeps nested generic types and Ruby parameter prefixes intact" do
    source = <<~RUBY
      class Example
        # **Parameters**
        #
        # - `options` (`Hash<String => Array<Integer>>`)
        # - `block` (`Proc`)
        #
        # **Returns**
        #
        # - `Boolean`
        def call(options = {}, &block)
          block.call(options)
        end
      end
    RUBY
    result = GraphQLDocs::TypeSignatureMigrator.new(paths: []).migrate(source)
    _(result).must_include("#   call(Hash[String, Array[Integer]] options, Proc &block) -> bool")
  end

  it "does not add signatures to nodoc objects" do
    source = <<~RUBY
      class Example
        # :nodoc:
        # **Returns**
        #
        # - `String`
        def call
          "hidden"
        end
      end
    RUBY

    result = GraphQLDocs::TypeSignatureMigrator.new(paths: []).migrate(source)

    _(result).wont_include(":call-seq:")
  end
end
