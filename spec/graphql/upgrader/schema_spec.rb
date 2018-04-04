# frozen_string_literal: true

require "spec_helper"
require './lib/graphql/upgrader/schema.rb'

describe GraphQL::Upgrader::Schema do
  def upgrade(old)
    GraphQL::Upgrader::Schema.new(old).upgrade
  end

  it 'updates the definition' do
    old = %{
      StarWarsSchema = GraphQL::Schema.define do
      end
    }
    new = %{
      class StarWarsSchema < GraphQL::Schema
      end
    }

    assert_equal upgrade(old), new
  end

  it 'updates the resolve_type' do
    old = %{
      StarWarsSchema = GraphQL::Schema.define do
        resolve_type ->(obj, ctx) do
          nil
        end
      end
    }
    new = %{
      class StarWarsSchema < GraphQL::Schema
        def self.resolve_type(obj, ctx)
          nil
        end
      end
    }

    assert_equal upgrade(old), new
  end

  it 'updates the object_from_id' do
    old = %{
      StarWarsSchema = GraphQL::Schema.define do
        object_from_id ->(id, ctx) do
          nil
        end
      end
    }
    new = %{
      class StarWarsSchema < GraphQL::Schema
        def self.object_from_id(id, ctx)
          nil
        end
      end
    }

    assert_equal upgrade(old), new
  end

  it 'updates the id_from_object' do
    old = %{
      StarWarsSchema = GraphQL::Schema.define do
        id_from_object -> (object, type_definition, ctx) do
          nil
        end
      end
    }
    new = %{
      class StarWarsSchema < GraphQL::Schema
        def self.id_from_object(object, type_definition, ctx)
          nil
        end
      end
    }

    assert_equal upgrade(old), new
  end


end
