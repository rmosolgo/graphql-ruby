# frozen_string_literal: true
require "graphql/compatibility/execution_specification/counter_schema"
require "graphql/compatibility/execution_specification/specification_schema"

module GraphQL
  module Compatibility
    # Test an execution strategy. This spec is not meant as a development aid.
    # Rather, when the strategy _works_, run it here to see if it has any differences
    # from the built-in strategy.
    #
    # - Custom scalar input / output
    # - Null propagation
    # - Query-level masking
    # - Directive support
    # - Typecasting
    # - Error handling (raise / return GraphQL::ExecutionError)
    # - Provides Irep & AST node to resolve fn
    # - Skipping fields
    #
    # Some things are explicitly _not_ tested here, because they're handled
    # by other parts of the system:
    #
    # - Schema definition (including types and fields)
    # - Parsing & parse errors
    # - AST -> IRep transformation (eg, fragment merging)
    # - Query validation and analysis
    # - Relay features
    #
    module ExecutionSpecification
      # Make a minitest suite for this execution strategy, making sure it
      # fulfills all the requirements of this library.
      # @param execution_strategy [<#new, #execute>] An execution strategy class
      # @return [Class<Minitest::Test>] A test suite for this execution strategy
      def self.build_suite(execution_strategy)
        GraphQL::Deprecation.warn "#{self} will be removed from GraphQL-Ruby 2.0. There is no replacement, please open an issue on GitHub if you need support."
        Class.new(Minitest::Test) do
          class << self
            attr_accessor :counter_schema, :specification_schema
          end

          self.specification_schema = SpecificationSchema.build(execution_strategy)
          self.counter_schema = CounterSchema.build(execution_strategy)

          def execute_query(query_string, **kwargs)
            kwargs[:root_value] = SpecificationSchema::DATA
            self.class.specification_schema.execute(query_string, **kwargs)
          end

          def test_it_fetches_data
            query_string = %|
            query getData($nodeId: ID = "1001") {
              flh: node(id: $nodeId) {
                __typename
                ... on Person {
                  name @include(if: true)
                  skippedName: name @skip(if: true)
                  birthdate
                  age(on: 1477660133)
                }

                ... on NamedEntity {
                  ne_tn: __typename
                  ne_n: name
                }

                ... on Organization {
                  org_n: name
                }
              }
            }
            |
            res = execute_query(query_string)

            assert_equal nil, res["errors"], "It doesn't have an errors key"

            flh = res["data"]["flh"]
            assert_equal "Fannie Lou Hamer", flh["name"], "It returns values"
            assert_equal Time.new(1917, 10, 6).to_i, flh["birthdate"], "It returns custom scalars"
            assert_equal 99, flh["age"], "It runs resolve functions"
            assert_equal "Person", flh["__typename"], "It serves __typename"
            assert_equal "Person", flh["ne_tn"], "It serves __typename on interfaces"
            assert_equal "Fannie Lou Hamer", flh["ne_n"], "It serves interface fields"
            assert_equal false, flh.key?("skippedName"), "It obeys @skip"
            assert_equal false, flh.key?("org_n"), "It doesn't apply other type fields"
          end

          def test_it_iterates_over_each
            query_string = %|
              query getData($nodeId: ID = "1002") {
                node(id: $nodeId) {
                  ... on Person {
                    organizations { name }
                  }
                }
              }
            |

            res = execute_query(query_string)
            assert_equal ["SNCC"], res["data"]["node"]["organizations"].map { |o| o["name"] }
          end

          def test_it_skips_skipped_fields
            query_str = <<-GRAPHQL
            {
              o3001: organization(id: "3001")  { name }
              o2001: organization(id: "2001")  { name }
            }
            GRAPHQL

            res = execute_query(query_str)
            assert_equal ["o2001"], res["data"].keys
            assert_equal false, res.key?("errors")
          end

          def test_it_propagates_nulls_to_field
            query_string = %|
            query getOrg($id: ID = "2001"){
              failure: node(id: $id) {
                ... on Organization {
                  name
                  leader { name }
                }
              }
              success: node(id: $id) {
                ... on Organization {
                  name
                }
              }
            }
            |
            res = execute_query(query_string)

            failure = res["data"]["failure"]
            success = res["data"]["success"]

            assert_equal nil, failure, "It propagates nulls to the next nullable field"
            assert_equal({"name" => "SNCC"}, success, "It serves the same object if no invalid null is encountered")
            assert_equal 1, res["errors"].length , "It returns an error for the invalid null"
          end

          def test_it_propages_nulls_to_operation
            query_string = %|
              {
                foundOrg: organization(id: "2001") {
                  name
                }
                organization(id: "2999") {
                  name
                }
              }
            |

            res = execute_query(query_string)
            assert_equal nil, res["data"]
            assert_equal 1, res["errors"].length
          end

          def test_it_exposes_raised_and_returned_user_execution_errors
            query_string = %|
              {
                organization(id: "2001") {
                  name
                  returnedError
                  raisedError
                }
                organizations {
                  returnedError
                  raisedError
                }
              }
            |

            res = execute_query(query_string)

            assert_equal "SNCC", res["data"]["organization"]["name"], "It runs the rest of the query"

            expected_errors = [
              {
                "message"=>"This error was returned",
                "locations"=>[{"line"=>5, "column"=>19}],
                "path"=>["organization", "returnedError"]
              },
              {
                "message"=>"This error was raised",
                "locations"=>[{"line"=>6, "column"=>19}],
                "path"=>["organization", "raisedError"]
              },
              {
                "message"=>"This error was raised",
                "locations"=>[{"line"=>10, "column"=>19}],
                "path"=>["organizations", 0, "raisedError"]
              },
              {
                "message"=>"This error was raised",
                "locations"=>[{"line"=>10, "column"=>19}],
                "path"=>["organizations", 1, "raisedError"]
              },
              {
                "message"=>"This error was returned",
                "locations"=>[{"line"=>9, "column"=>19}],
                "path"=>["organizations", 0, "returnedError"]
              },
              {
                "message"=>"This error was returned",
                "locations"=>[{"line"=>9, "column"=>19}],
                "path"=>["organizations", 1, "returnedError"]
              },
            ]

            expected_errors.each do |expected_err|
              assert_includes res["errors"], expected_err
            end
          end

          def test_it_applies_masking
            no_org = ->(member, ctx) { member.name == "Organization" }
            query_string = %|
            {
              node(id: "2001") {
                __typename
              }
            }|

            err = assert_raises(GraphQL::UnresolvedTypeError) {
              execute_query(query_string, except: no_org)
            }

            query_string = %|
            {
              organization(id: "2001") { name }
            }|

            res = execute_query(query_string, except: no_org)

            assert_equal nil, res["data"]
            assert_equal 1, res["errors"].length
            assert_equal "SNCC", err.value.name
            assert_equal GraphQL::Relay::Node.interface, err.field.type
            assert_equal 1, err.possible_types.length
            assert_equal "Organization", err.resolved_type.name
            assert_equal "Query", err.parent_type.name

            query_string = %|
            {
              __type(name: "Organization") { name }
            }|

            res = execute_query(query_string, except: no_org)

            assert_equal nil, res["data"]["__type"]
            assert_equal nil, res["errors"]
          end

          def test_it_provides_nodes_to_resolve
            query_string = %|
            {
              organization(id: "2001") {
                name
                nodePresence
              }
            }|

            res = execute_query(query_string)
            assert_equal "SNCC", res["data"]["organization"]["name"]
            assert_equal [true, true, false], res["data"]["organization"]["nodePresence"]
          end

          def test_it_runs_the_introspection_query
            execute_query(GraphQL::Introspection::INTROSPECTION_QUERY)
          end

          def test_it_propagates_deeply_nested_nulls
            query_string = %|
            {
              node(id: "1001") {
                ... on Person {
                  name
                  first_organization {
                    leader {
                      name
                    }
                  }
                }
              }
            }
            |
            res = execute_query(query_string)
            assert_equal nil, res["data"]["node"]
            assert_equal 1, res["errors"].length
          end

          def test_it_doesnt_add_errors_for_invalid_nulls_from_execution_errors
            query_string = %|
            query getOrg($id: ID = "2001"){
              failure: node(id: $id) {
                ... on Organization {
                  name
                  leader { name }
                }
              }
            }
            |
            res = execute_query(query_string, context: {return_error: true})
            error_messages = res["errors"].map { |e| e["message"] }
            assert_equal ["Error on Nullable"], error_messages
          end

          def test_it_only_resolves_fields_once_on_typed_fragments
            res = self.class.counter_schema.execute("
            {
              counter { count }
              ... on HasCounter {
                counter { count }
              }
            }
            ")

            expected_data = {
              "counter" => { "count" => 1 }
            }
            assert_equal expected_data, res["data"]
            assert_equal 1, self.class.counter_schema.metadata[:count]

            # Deep typed children are correctly distinguished:
            res = self.class.counter_schema.execute("
            {
              counter {
                ... on Counter {
                  counter { count }
                }
                ... on AltCounter {
                  counter { count, t: __typename }
                }
              }
            }
            ")

            expected_data = {
              "counter" => { "counter" => { "count" => 2 } }
            }
            assert_equal expected_data, res["data"]
          end

          def test_it_runs_middleware
            log = []
            query_string = %|
            {
              node(id: "2001") {
                __typename
              }
            }|
            execute_query(query_string, context: {middleware_log: log})
            assert_equal ["node", "__typename"], log
          end

          def test_it_uses_type_error_hooks_for_invalid_nulls
            log = []
            query_string = %|
            {
              node(id: "1001") {
                ... on Person {
                  name
                  first_organization {
                    leader {
                      name
                    }
                  }
                }
              }
            }|

            res = execute_query(query_string, context: { type_errors: log })
            assert_equal nil, res["data"]["node"]
            assert_equal [nil], log
          end

          def test_it_uses_type_error_hooks_for_failed_type_resolution
            log = []
            query_string = %|
            {
              node(id: "2003") {
                __typename
              }
            }|

            assert_raises(GraphQL::UnresolvedTypeError) {
              execute_query(query_string, context: { type_errors: log })
            }

            assert_equal [SpecificationSchema::BOGUS_NODE], log
          end

          def test_it_treats_failed_type_resolution_like_nil
            log = []
            ctx = { type_errors: log, gobble: true }
            query_string = %|
            {
              node(id: "2003") {
                __typename
              }
            }|

            res = execute_query(query_string, context: ctx)

            assert_equal nil, res["data"]["node"]
            assert_equal false, res.key?("errors")
            assert_equal [SpecificationSchema::BOGUS_NODE], log

            query_string_2 = %|
            {
              requiredNode(id: "2003") {
                __typename
              }
            }|

            res = execute_query(query_string_2, context: ctx)

            assert_equal nil, res["data"]
            assert_equal false, res.key?("errors")
            assert_equal [SpecificationSchema::BOGUS_NODE, SpecificationSchema::BOGUS_NODE], log
          end

          def test_it_skips_connections
            query_type = GraphQL::ObjectType.define do
              name "Query"
              connection :skipped, types[query_type], resolve: ->(o,a,c) { c.skip }
            end
            schema = GraphQL::Schema.define(query: query_type)
            res = schema.execute("{ skipped { __typename } }")
            assert_equal({"data" => nil}, res)
          end
        end
      end
    end
  end
end
