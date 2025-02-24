# frozen_string_literal: true
require "test_helper"

class DashboardTracesControllerTest < ActionDispatch::IntegrationTest
  def test_it_renders_not_installed
    get graphql_dashboard.traces_path, params: { schema: "NotInstalledSchema" }
    assert_includes response.body, "Traces aren't installed yet"
    assert_includes response.body, "<code>NotInstalledSchema</code>"
  end

  def test_it_renders_blank_state
    get graphql_dashboard.traces_path
    assert_includes response.body, "No traces saved yet."
    assert_includes response.body, "<code>DummySchema</code>"
  end

  def test_it_renders_trace_listing_with_pagination
    skip :TODO
  end

  def test_it_deletes_one_trace
    DummySchema.execute("{ str }", context: { trace_mode: :perfetto_sample })
    assert_equal 1, DummySchema.perfetto_sampler.traces.size
    id = DummySchema.perfetto_sampler.traces.first.id
    delete graphql_dashboard.trace_path(id: id)
    assert_equal 0, DummySchema.perfetto_sampler.traces.size
  end

  def test_it_delets_all_traces
    skip :TODO
  end
end
