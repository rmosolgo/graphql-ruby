# frozen_string_literal: true
require "spec_helper"
require "rake"
require "graphql/rake_task"

describe "graphql:pro:validate" do
  let(:creds) { "abcdefghijk:lmnopqrstuv" }
  let(:digest) { "a" * 128 }

  def run_validate(version)
    task = Rake::Task["graphql:pro:validate"]
    task.reenable
    out, _err = capture_io { task.invoke(version) }
    out
  end

  def with_stubs(creds: self.creds, gem_digest: digest, published: digest)
    validate = GraphQL::RakeTask::Validate
    fetched_versions = []
    fetch_gem = ->(version, c) { fetched_versions << [version, c]; gem_digest }
    validate.stub(:credentials, creds) do
      validate.stub(:fetch_gem_digest, fetch_gem) do
        validate.stub(:fetch_published_digest, ->(_uri) { published }) do
          yield(fetched_versions)
        end
      end
    end
  end

  describe "version validation" do
    ["1.0.0; id", "$(id)", "`id`", "../../etc/passwd", "1.0.0 && rm -rf /", "1.0.0|cat", "", "  ", nil].each do |bad_version|
      it "rejects #{bad_version.inspect} without fetching anything" do
        with_stubs do |fetched|
          assert_raises(ArgumentError) { run_validate(bad_version) }
          assert_equal [], fetched
        end
      end
    end

    it "normalizes surrounding whitespace" do
      assert_equal "1.2.3", GraphQL::RakeTask::Validate.normalize_version(" 1.2.3\n")
      assert_equal "1.2.3.pre", GraphQL::RakeTask::Validate.normalize_version("1.2.3.pre")
    end
  end

  it "validates a matching download" do
    with_stubs do |fetched|
      out = run_validate("1.2.3")
      assert_includes out, "graphql-pro 1.2.3 validated successfully!"
      assert_equal [["1.2.3", creds]], fetched
      refute_includes out, creds
    end
  end

  it "exits on a digest mismatch" do
    with_stubs(published: "b" * 128) do
      assert_raises(SystemExit) { run_validate("1.2.3") }
    end
  end

  it "exits when published digests are missing" do
    with_stubs(published: nil) do
      assert_raises(SystemExit) { run_validate("1.2.3") }
    end
  end

  it "exits when credentials are missing" do
    with_stubs(creds: nil) do |fetched|
      assert_raises(SystemExit) { run_validate("1.2.3") }
      assert_equal [], fetched
    end
  end

  it "exits when the gem can't be fetched" do
    with_stubs(gem_digest: nil) do
      assert_raises(SystemExit) { run_validate("1.2.3") }
    end
  end

  describe ".fetch_gem_digest" do
    it "sends credentials as a Basic auth header, not in the URL" do
      requests = []
      fake_http = Object.new
      fake_http.define_singleton_method(:request) do |req|
        requests << req
        res = Net::HTTPOK.new("1.1", "200", "OK")
        res.instance_variable_set(:@read, true)
        res.instance_variable_set(:@body, "gem contents")
        res
      end
      Net::HTTP.stub(:start, ->(*_args, **_kw, &blk) { blk.call(fake_http) }) do
        digest = GraphQL::RakeTask::Validate.fetch_gem_digest("1.2.3", creds)
        assert_equal Digest::SHA512.hexdigest("gem contents"), digest
      end
      req = requests.first
      assert_equal "/gems/graphql-pro-1.2.3.gem", req.path
      assert_equal "Basic #{["#{creds}"].pack("m0")}", req["Authorization"]
      refute_includes req.uri.to_s, creds
    end
  end
end
