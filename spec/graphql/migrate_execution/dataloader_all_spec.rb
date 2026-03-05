# frozen_string_literal: true
require "spec_helper"
require "graphql/migrate_execution"
require_relative "./strategy_helpers"

describe "DataloaderAll migration strategy" do
  include GraphQLMigrateExecutionStrategyHelpers
  before do
    @strategy_class = GraphQL::MigrateExecution::DataloaderAll
  end

  it "turns single dataloader .load calls to list calls" do
    input = <<-RUBY # Don't use squiggles to check leading whitespace preservation
    class Thing < Types::BaseObject
      field :user_points, Int

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object)
      end
    end
    RUBY


    expected_result = <<-RUBY
    class Thing < Types::BaseObject
      field :user_points, Int, resolve_batch: true

      def self.user_points(objects, context)
        context.dataload_all(Sources::UserPoints, objects)
      end

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object)
      end
    end
    RUBY

    assert_equal expected_result, add_future(input)
    assert input.end_with?("\n")
    assert add_future(input).end_with?("\n")
  end

  it "turns dataload calls to list calls, preserving source arguments" do
    expected_result = <<~RUBY
    class Thing < BaseObject
      field :user_points, Int, resolve_batch: true

      def self.user_points(objects, context, mode:)
        context.dataload_all(Sources::UserPoints, SomeConst, mode, objects)
      end

      def user_points(mode:)
        dataload(Sources::UserPoints, SomeConst, mode, object)
      end
    end
    RUBY

    assert_equal expected_result, add_future(<<~RUBY)
    class Thing < BaseObject
      field :user_points, Int

      def user_points(mode:)
        dataload(Sources::UserPoints, SomeConst, mode, object)
      end
    end
    RUBY
  end

  it "turns request calls to list calls" do
    expected_result = <<~RUBY
    class Thing < BaseObject
      field :user_points, Integer, resolve_batch: :get_user_points, resolver_method: :get_user_points

      def self.get_user_points objects, context, mode:
        context.dataload_all(Sources::UserPoints, mode, objects)
      end

      def get_user_points mode:
        dataloader.with(Sources::UserPoints, mode).request(object)
      end
    end
    RUBY

    assert_equal expected_result, add_future(<<~RUBY)
    class Thing < BaseObject
      field :user_points, Integer, resolver_method: :get_user_points

      def get_user_points mode:
        dataloader.with(Sources::UserPoints, mode).request(object)
      end
    end
    RUBY
  end

  it "turns object method calls to map calls" do
    expected_result = <<~RUBY
    class Thing < BaseObject
      field :user_points, Int, resolve_batch: true

      def self.user_points(objects, context)
        context.dataload_all(Sources::UserPoints, objects.map(&:points_id))
      end

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object.points_id)
      end
    end
    RUBY

    assert_equal expected_result, add_future(<<~RUBY)
    class Thing < BaseObject
      field :user_points, Int

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object.points_id)
      end
    end
    RUBY

    expected_result = <<~RUBY
    class Thing < BaseObject
      field :user_points, Int, resolve_batch: true
      def self.user_points(objects, context)
        context.dataload_all(Sources::UserPoints, objects.map { |obj| obj.user.id })
      end

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object.user.id)
      end
    end
    RUBY

    assert_equal expected_result, add_future(<<~RUBY)
    class Thing < BaseObject
      field :user_points, Int
      def user_points
        context.dataloader.with(Sources::UserPoints).load(object.user.id)
      end
    end
    RUBY
  end

  it "also transforms key accesses" do
    expected_result = <<~RUBY
    class Thing < BaseObject
      field :user_points, Int, resolve_batch: true

      def self.user_points(objects, context)
        context.dataload_all(Sources::UserPoints, objects.map { |obj| obj[:user].points["id"][1].to_s })
      end

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object[:user].points["id"][1].to_s)
      end
    end
    RUBY

    assert_equal expected_result, add_future(<<~RUBY)
    class Thing < BaseObject
      field :user_points, Int

      def user_points
        context.dataloader.with(Sources::UserPoints).load(object[:user].points["id"][1].to_s)
      end
    end
    RUBY

    expected_migrated = <<~RUBY
    class Thing < BaseObject
      field :user_points, Int, resolve_batch: true

      def self.user_points(objects, context)
        context.dataload_all(Sources::UserPoints, objects.map { |obj| obj[:user].points["id"][1].to_s })
      end
    end
    RUBY
    assert_equal expected_migrated, remove_legacy(expected_result)
  end
end
