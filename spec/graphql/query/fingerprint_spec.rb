# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Fingerprint do
  def build_query(str, var)
    GraphQL::Query.new(Dummy::Schema, str, variables: var)
  end

  it "makes stable variable fingerprints" do
    var1a = { "a" => 1, "b" => 2 }
    var1b = { "a" => 1, "b" => 2 }
    # These keys are in a different order -- they'll be hashed differently.
    var2  = { "b" => 2, "a" => 1 }

    str = "{ __typename }"
    expected_fingerprint = "QyWM_3g_5wNtikMDP4MK38YOwDc4JHNUisdCuIgpJ3c="
    assert_equal expected_fingerprint, build_query(str, var1a).variables_fingerprint
    assert_equal expected_fingerprint, build_query(str, var1b).variables_fingerprint
    other_expected_fingerprint = "P7dUUyJccyp2t4meoglt2hRVGJyJgXI5cyGC9z_loJ8="
    assert_equal other_expected_fingerprint, build_query(str, var2).variables_fingerprint
  end

  it "makes stable query fingerprints" do
    str1a = "{ __typename }"
    str1b = "{ __typename }"
    # Different whitespace is a different query
    str2  = "{\n  __typename\n}\n"
    expected_fingerprint = "f1bmfdIas_MNH_i3vtCIk_Cg24ZEmDYYmzYd0eVt20s="
    assert_equal expected_fingerprint, build_query(str1a, {}).query_fingerprint
    assert_equal expected_fingerprint, build_query(str1b, {}).query_fingerprint
    other_expected_fingerprint = "jY9zZenob6jjMT_K8hMbgB6v6VSd4iNzCJzydRGFizk="
    assert_equal other_expected_fingerprint, build_query(str2, {}).query_fingerprint
  end

  it "makes combined fingerprints" do
    str1a = "{ __typename }"
    str1b = "{ __typename }"
    str1_fingerprint = "f1bmfdIas_MNH_i3vtCIk_Cg24ZEmDYYmzYd0eVt20s="

    # Different whitespace is a different query
    str2  = "{\n  __typename\n}\n"
    str2_fingerprint = "jY9zZenob6jjMT_K8hMbgB6v6VSd4iNzCJzydRGFizk="

    var1a = { "a" => 1, "b" => 2 }
    var1b = { "a" => 1, "b" => 2 }
    var1_fingerprint = "QyWM_3g_5wNtikMDP4MK38YOwDc4JHNUisdCuIgpJ3c="

    # These keys are in a different order -- they'll be hashed differently.
    var2  = { "b" => 2, "a" => 1 }
    var2_fingerprint = "P7dUUyJccyp2t4meoglt2hRVGJyJgXI5cyGC9z_loJ8="

    assert_equal "#{str1_fingerprint}/#{var1_fingerprint}", build_query(str1a, var1a).fingerprint
    assert_equal "#{str1_fingerprint}/#{var1_fingerprint}", build_query(str1b, var1b).fingerprint
    assert_equal "#{str2_fingerprint}/#{var2_fingerprint}", build_query(str2, var2).fingerprint
    assert_equal "#{str1_fingerprint}/#{var2_fingerprint}", build_query(str1a, var2).fingerprint
    assert_equal "#{str2_fingerprint}/#{var1_fingerprint}", build_query(str2, var1b).fingerprint
  end
end
