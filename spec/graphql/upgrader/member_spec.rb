# frozen_string_literal: true
require "spec_helper"
require './lib/graphql/upgrader/member.rb'

describe GraphQL::Upgrader::Member do
  def transform(old)
    GraphQL::Upgrader::Member.new(old).transform
  end

  # Missing transformation
  describe 'field arguments' do
    # old: argument :status, !TodoStatus, "Restrict items to this status"
    # new: argument :status, TodoStatus, "Restrict items to this status", null: true
  end

  # Tests not ported from gem to PR
  describe 'definition' do
    # .define -> Class
    # - Object classes
    # - Interface classes
    # - Union classes
    # - Enum classes
  end

  # Tests not ported from gem to PR
  describe 'name' do
    # Removes name if it's not needed, otherwise it creates the graphql_name
  end

  describe 'fields' do
    it 'transforms to the new definition' do
      old = %{field :name, !types.String}
      new = %{field :name, String, null: true}
      assert_equal transform(old), new

      old = %{field :name, !types.String, "description", property: :name}
      new = %{field :name, String, "description", property: :name, null: true}
      assert_equal transform(old), new

      old = %{field :name, -> { !types.String }}
      new = %{field :name, -> { String }, null: true}
      assert_equal transform(old), new

      old = %{connection :name, Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", connection: true}
      assert_equal transform(old), new

      old = %{connection :name, !Name.connection_type, "names"}
      new = %{field :name, Name.connection_type, "names", null: true, connection: true}
      assert_equal transform(old), new

      old = %{field :names, types[types.String]}
      new = %{field :names, [String]}
      assert_equal transform(old), new

      old = %{field :names, !types[types.String]}
      new = %{field :names, [String], null: true}
      assert_equal transform(old), new

      old = %{|
        field :name, types.String do
        end
      |}
      new = %{|
        field :name, String do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name, !types.String do
        end
      |}
      new = %{|
        field :name, String, null: true do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name, -> { !types.String } do
        end
      |}
      new = %{|
        field :name, -> { String }, null: true do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name do
          type -> { String }
        end
      |}
      new = %{|
        field :name, -> { String } do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name do
          type !String
        end
      |}
      new = %{|
        field :name, String, null: true do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name, -> { types.String },
          "newline description" do
        end
      |}
      new = %{|
        field :name, -> { String }, "newline description" do
        end
      |}
      assert_equal transform(old), new

      old = %{|
        field :name, -> { !types.String },
          "newline description" do
        end
      |}
      new = %{|
        field :name, -> { String }, "newline description", null: true do
        end
      |}
      assert_equal transform(old), new
    end

    it 'does not transform when its not needed' do
      old = %{|
       field :name, String,
         field: SomeField do
       end
      |}
      new = %{|
       field :name, String,
         field: SomeField do
       end
      |}
      assert_equal transform(old), new
    end
  end
end
