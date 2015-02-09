class GraphQL::Introspection::FieldsEdge < GraphQL::CollectionEdge
  def apply_calls(unfiltered, call_hash)
    present_calls = call_hash.keys & ["first", "last"]
    present_calls.each do |call_name|
      unfiltered = unfiltered.send(call_name, call_hash[call_name].first.to_i)
    end
    unfiltered
  end
end