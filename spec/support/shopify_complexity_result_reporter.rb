# frozen_string_literal: true

class ShopifyComplexityResultReporter
  def initialize
    @results = []
    @errors = []
  end

  attr_reader :results, :errors

  # Record a successful query result
  def add_result(name:, estimated:, actual:, fields: nil)
    diff = estimated - actual
    percent_diff = actual > 0 ? ((diff.to_f / actual) * 100).round(1) : 0

    @results << {
      name: name,
      estimated: estimated,
      actual: actual,
      diff: diff,
      percent_diff: percent_diff,
      fields: fields
    }
  end

  # Record an error during query processing
  def add_error(name:, error:)
    @errors << {
      name: name,
      error: error
    }
  end

  # Print a single query result (during execution)
  def print_query_status(query_index, total_queries, query_name, estimated, actual, diff, percent_diff)
    puts "  Estimated: #{estimated}, Actual: #{actual}, Diff: #{diff} (#{percent_diff}%)"
  end

  # Print summary table of all results
  def print_summary
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    printf "%-40s %10s %10s %10s %10s\n", "Query", "Estimated", "Actual", "Diff", "Diff %"
    puts "-" * 80

    results.each do |r|
      printf "%-40s %10d %10d %10d %9.1f%%\n",
             r[:name].slice(0, 40),
             r[:estimated],
             r[:actual],
             r[:diff],
             r[:percent_diff]
    end
  end

  # Print errors that occurred during processing
  def print_errors
    return unless errors.any?

    puts "\n" + "=" * 80
    puts "ERRORS (#{errors.size})"
    puts "=" * 80
    errors.each do |e|
      puts "#{e[:name]}: #{e[:error]}"
    end
  end

  # Print statistics about the results
  def print_statistics(total_queries)
    return unless results.any?

    avg_diff = (results.sum { |r| r[:diff].abs } / results.size.to_f).round(1)
    avg_percent_diff = (results.sum { |r| r[:percent_diff].abs } / results.size.to_f).round(1)

    puts "\n" + "=" * 80
    puts "Average absolute difference: #{avg_diff} (#{avg_percent_diff}%)"
    puts "Successful queries: #{results.size}/#{total_queries}"
    puts "=" * 80
  end

  # Print all reports in order (summary, errors, statistics)
  def print_all(total_queries)
    print_summary
    print_errors
    print_statistics(total_queries)
  end

  # Check if all results passed (0% difference or within tolerance)
  def all_passed?(tolerance_percent = 0.0)
    results.all? { |r| r[:percent_diff].abs <= tolerance_percent }
  end

  # Get average difference across all results
  def average_difference
    return 0 if results.empty?
    (results.sum { |r| r[:diff].abs } / results.size.to_f).round(1)
  end

  # Get average percent difference across all results
  def average_percent_difference
    return 0 if results.empty?
    (results.sum { |r| r[:percent_diff].abs } / results.size.to_f).round(1)
  end
end
