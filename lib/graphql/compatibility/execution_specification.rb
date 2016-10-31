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
      DATA = {
        "1001" => OpenStruct.new({
          name: "Fannie Lou Hamer",
          birthdate: Time.new(1917, 10, 6),
          organization_ids: [],
        }),
        "1002" => OpenStruct.new({
          name: "John Lewis",
          birthdate: Time.new(1940, 2, 21),
          organization_ids: ["2001"],
        }),
        "1003" => OpenStruct.new({
          name: "Diane Nash",
          birthdate: Time.new(1938, 5, 15),
          organization_ids: ["2001", "2002"],
        }),
        "1004" => OpenStruct.new({
          name: "Ralph Abernathy",
          birthdate: Time.new(1926, 3, 11),
          organization_ids: ["2002"],
        }),
        "2001" => OpenStruct.new({
          name: "SNCC",
          leader_id: nil, # fail on purpose
        }),
        "2002" => OpenStruct.new({
          name: "SCLC",
          leader_id: "1004",
        }),
      }

      # Make a minitest suite for this execution strategy, making sure it
      # fulfills all the requirements of this library.
      # @param execution_strategy [<#new, #execute>] An execution strategy class
      # @return [Class<Minitest::Test>] A test suite for this execution strategy
      def self.build_suite(execution_strategy)
        Class.new(Minitest::Test) do
          def self.build_schema(execution_strategy)
            organization_type = nil

            timestamp_type = GraphQL::ScalarType.define do
              name "Timestamp"
              coerce_input ->(value) { Time.at(value.to_i) }
              coerce_result ->(value) { value.to_i }
            end

            named_entity_interface_type = GraphQL::InterfaceType.define do
              name "NamedEntity"
              field :name, !types.String
            end

            person_type = GraphQL::ObjectType.define do
              name "Person"
              interfaces [named_entity_interface_type]
              field :name, !types.String
              field :birthdate, timestamp_type
              field :age, types.Int do
                argument :on, !timestamp_type
                resolve ->(obj, args, ctx) {
                  if obj.birthdate.nil?
                    nil
                  else
                    age_on = args[:on]
                    age_years = age_on.year - obj.birthdate.year
                    this_year_birthday = Time.new(age_on.year, obj.birthdate.month, obj.birthdate.day)
                    if this_year_birthday > age_on
                      age_years -= 1
                    end
                  end
                  age_years
                }
              end
              field :organizations, types[organization_type] do
                resolve ->(obj, args, ctx) {
                  obj.organization_ids.map { |id| DATA[id] }
                }
              end
            end

            organization_type = GraphQL::ObjectType.define do
              name "Organization"
              interfaces [named_entity_interface_type]
              field :name, !types.String
              field :leader, !person_type do
                resolve ->(obj, args, ctx) {
                  DATA[obj.leader_id]
                }
              end
              field :returnedError, types.String do
                resolve ->(o, a, c) {
                  GraphQL::ExecutionError.new("This error was returned")
                }
              end
              field :raisedError, types.String do
                resolve ->(o, a, c) {
                  raise GraphQL::ExecutionError.new("This error was raised")
                }
              end

              field :nodePresence, !types[!types.Boolean] do
                resolve ->(o, a, ctx) {
                  [
                    ctx.irep_node.is_a?(GraphQL::InternalRepresentation::Node),
                    ctx.ast_node.is_a?(GraphQL::Language::Nodes::AbstractNode),
                    false, # just testing
                  ]
                }
              end
            end

            node_union_type = GraphQL::UnionType.define do
              name "Node"
              possible_types [person_type, organization_type]
            end

            query_type = GraphQL::ObjectType.define do
              name "Query"
              field :node, node_union_type do
                argument :id, !types.ID
                resolve ->(obj, args, ctx) {
                  obj[args[:id]]
                }
              end

              field :organization, !organization_type do
                argument :id, !types.ID
                resolve ->(obj, args, ctx) {
                  args[:id].start_with?("2") && obj[args[:id]]
                }
              end
            end

            GraphQL::Schema.define do
              query_execution_strategy execution_strategy
              query query_type

              resolve_type ->(obj, ctx) {
                obj.respond_to?(:birthdate) ? person_type : organization_type
              }
            end
          end

          @@schema = build_schema(execution_strategy)

          def execute_query(query_string, **kwargs)
            kwargs[:root_value] = DATA
            @@schema.execute(query_string, **kwargs)
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
              }
            |

            res = execute_query(query_string)

            assert_equal "SNCC", res["data"]["organization"]["name"], "It runs the rest of the query"

            expected_returned_error = {
              "message"=>"This error was returned",
              "locations"=>[{"line"=>5, "column"=>19}],
              "path"=>["organization", "returnedError"]
            }
            assert_includes res["errors"], expected_returned_error, "It turns returned errors into response errors"

            expected_raised_error = {
              "message"=>"This error was raised",
              "locations"=>[{"line"=>6, "column"=>19}],
              "path"=>["organization", "raisedError"]
            }
            assert_includes res["errors"], expected_raised_error, "It turns raised errors into response errors"
          end

          def test_it_applies_masking
            no_org = ->(member) { member.name == "Organization" }
            query_string = %|
            {
              node(id: "2001") {
                __typename
              }
            }|

            assert_raises(GraphQL::UnresolvedTypeError) {
              execute_query(query_string, except: no_org)
            }

            query_string = %|
            {
              organization(id: "2001") { name }
            }|

            res = execute_query(query_string, except: no_org)

            assert_equal nil, res["data"]
            assert_equal 1, res["errors"].length

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
            skip
          end

          def test_it_doesnt_add_errors_for_invalid_nulls_from_execution_errors
            skip
          end

          def test_it_passes_invalid_nulls_to_schema
            skip
          end

          def test_it_includes_path_and_index_in_error_path
            skip
          end
        end
      end
    end
  end
end
