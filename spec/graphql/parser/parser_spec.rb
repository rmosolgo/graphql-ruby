require 'spec_helper'

describe GraphQL::Parser::Parser do
  let(:parser) { GraphQL::PARSER }

  describe 'query' do
    let(:query) { parser.query }
    it 'parses node-only' do
      assert query.parse_with_debug("node(4) { id, name } ")
    end
    it 'parses node and variables' do
      assert query.parse_with_debug(%{
        like_page(<page>) {
          page { id }
        }
        <page>: {
          "page": {"id": 1},
          "person" : { "id", 4}
        }
        <other>: {
          "page": {"id": 1},
          "person" : { "id", 4}
        }
      })
    end
  end
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

    it 'finds calls with variables' do
      assert call.parse_with_debug("like_page(<page>)")
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
      assert node.parse_with_debug("
        node(someone)
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

  describe 'variable' do
    let(:variable) { parser.variable }

    it 'gets scalar variables' do
      assert variable.parse_with_debug(%{<some_number>: 888})
      assert variable.parse_with_debug(%{<some_string>: my_string})
    end
    it 'gets json variables' do
      assert variable.parse_with_debug(%{<my_input>: {"key": "value"}})
    end

    it 'gets variables with nesting' do
      assert variable.parse_with_debug(%{
      <my_input>: {
        "key": "value",
        "1": 2,
        "true": false,
        "nested": {
          "key" : "value"
          }
        }
      })
    end
  end
end