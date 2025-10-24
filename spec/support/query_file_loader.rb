# frozen_string_literal: true

# Utility to load GraphQL query files for testing
class QueryFileLoader
  # Load a random sample of query files from a directory
  # @param dir [String] Directory path containing .graphql files
  # @param count [Integer] Number of random queries to load
  # @return [Array<Hash>] Array of { path:, content:, name: }
  def self.load_random_queries(dir, count)
    select_only = ENV.fetch("SHOPIFY_SELECT_ONLY", "").split(",")

    query_files = Dir.glob(File.join(dir, "*.graphql")).filter_map do |file_path|
      content = File.read(file_path)

      # Skip fragments and mutations
      next if fragment_only?(content) || mutation?(content)

      # Skip if doesn't match select_only filter
      next unless select_only.empty? || select_only?(content, select_only)

      {
        path: file_path,
        name: File.basename(file_path, ".graphql"),
        content: content
      }
    end

    query_files.sample(count)
  end

  # Check if a query string is fragment-only (no query/mutation)
  # @param query_string [String] The GraphQL query
  # @return [Boolean]
  def self.fragment_only?(query_string)
    query_string.strip.start_with?("fragment")
  end

  # Check if a query string is a mutation
  # @param query_string [String] The GraphQL query
  # @return [Boolean]
  def self.mutation?(query_string)
    query_string.match?(/\bmutation\b/)
  end

  def self.select_only?(query_string, select_only)
    select_only.any? { |selection| query_string.match?(/\b#{selection}\b/) }
  end

  # Get default variables for common query patterns
  # @param query_string [String] The GraphQL query
  # @return [Hash] Default variables to use
  def self.default_variables(query_string)
    vars = {}
    variables = extract_variables(query_string)

    variables.each do |var_name|
      case var_name
      when "first"
        # Always provide first if it's a variable (prefer first over last)
        vars[var_name] = 10
      when "last"
        # Only provide last if first is NOT a variable
        vars[var_name] = 10 unless variables.include?("first")
      when "after", "before"
        vars[var_name] = nil
      when /count|length/i
        # Variables with "count" or "length" are typically pagination params
        # Check this BEFORE /query/i to avoid matching "queryLength"
        vars[var_name] = 10
      when /query/i
        # Any variable with "query" in the name gets empty string
        vars[var_name] = ""
      when /id/i
        # Get ID from variable name
        vars[var_name] = id_for_variable(var_name)
      else
        # Skip unknown variables
        vars[var_name] = nil
      end
    end
    vars.compact
  end

  # Extract variable definitions from a query string
  # @param query_string [String] The GraphQL query
  # @return [Array<String>] Variable names (without $)
  def self.extract_variables(query_string)
    query_string.scan(/\$(\w+):\s*\w+/).flatten.uniq
  end

  # Map variable names to appropriate Shopify GIDs
  # @param var_name [String] The variable name
  # @return [String, nil] The GID or nil if not recognized
  def self.id_for_variable(var_name)
    case var_name.downcase
    when "productid", "product_id"
      # TODO: Implement this
    when "variantid", "variant_id"
      # TODO: Implement this
    when "inventoryitemid", "inventory_item_id"
      # TODO: Implement this
    when "inventorylevelid", "inventory_level_id"
      # TODO: Implement this
    when "orderid", "order_id"
      # TODO: Implement this
    when "fulfillmentid", "fulfillment_id"
      # TODO: Implement this
    when "lineitemid", "line_item_id", "orderlineitemid", "order_line_item_id"
      # TODO: Implement this
    when "fulfillmentlineitemid", "fulfillment_line_item_id"
      # TODO: Implement this
    when "fulfillmentorderid", "fulfillment_order_id"
      # TODO: Implement this
    when "reversefulfillmentorderid", "reverse_fulfillment_order_id"
      # TODO: Implement this
    when "reversefulfillmentorderlineitemid", "reverse_fulfillment_order_line_item_id"
      # TODO: Implement this
    when "returnlineitemid", "return_line_item_id"
      # TODO: Implement this
    when "dispositionid", "disposition_id"
      # TODO: Implement this
    when "locationid", "location_id"
      # TODO: Implement this
    when "collectionid", "collection_id"
      # TODO: Implement this
    when "fulfillmentserviceid", "fulfillment_service_id"
      # TODO: Implement this
    when "refundid", "refund_id"
      # TODO: Implement this
    when "returnid", "return_id"
      # TODO: Implement this
    else
      # Don't provide a generic fallback - if we don't recognize the ID type,
      # return nil so the query fails and we can add proper handling
      nil
    end
  end
end
