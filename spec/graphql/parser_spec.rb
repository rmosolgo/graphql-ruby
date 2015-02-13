require 'spec_helper'

describe GraphQL::Parser do
  let(:parser) { GraphQL::PARSER }

  describe 'field' do
    let(:field) { parser.field }
    it 'finds words' do
      assert field.parse_with_debug("date_of_birth")
    end

    it 'finds aliases' do
      assert field.parse_with_debug("name as moniker")
    end

    it 'finds calls on fields' do
      assert field.parse_with_debug("url.site(www).upcase()")
    end

    describe 'fields that return objects' do
      it 'finds them' do
        assert field.parse_with_debug("birthdate { month, year }")
      end

      it 'finds them with aliases' do
        assert field.parse_with_debug("birthdate as d_o_b { month, year }")
      end

      it 'finds them with calls' do
        assert field.parse_with_debug("friends.after(123) { count { edges { node { id } } } }")
      end

      it 'finds them with calls and aliases' do
        assert field.parse_with_debug("friends.after(123) as pals { count { edges { node { id } } } }")
      end
    end
  end

  describe 'call' do
    let(:call) { parser.call }
    it 'finds bare calls' do
      assert call.parse_with_debug("node(123)")
      assert call.parse_with_debug("viewer()")
    end

    it 'finds calls with multiple arguments' do
      assert call.parse_with_debug("node(4, 6)")
    end
  end

  describe 'fields' do
    let(:fields) { parser.fields }

    it 'finds fields' do
      assert fields.parse_with_debug("{id,name}")
      assert fields.parse_with_debug("{ id, name, favorite_food }")
      assert fields.parse_with_debug("{\n  id,\n  name,\n  favorite_food\n}")
    end

    it 'finds nested field list' do
      assert fields.parse_with_debug("{id,date_of_birth{month, year}}")
    end
  end

  describe 'node' do
    let(:node) { parser.node }

    it 'parses root calls' do
      assert node.parse_with_debug("viewer() {id}")
    end

    it 'parses nested nodes' do
      assert node.parse_with_debug("node(someone)
            {
              id,
              name,
              friends.after(12345).first(3) {
                cursor,
                node {
                  id,
                  name
                }
              }
            }
          ")
    end
  end
end