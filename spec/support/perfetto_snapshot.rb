# frozen_string_literal: true
module PerfettoSnapshot
  def check_snapshot(data, snapshot_name)
    prev_file = caller(1, 1).first.sub(/\/[a-z_]*\.rb:.*/, "")
    snapshot_dir = prev_file + "/snapshots"
    snapshot_path = "#{snapshot_dir}/#{snapshot_name}"

    if ENV["UPDATE_PERFETTO"]
      puts "Updating PerfettoTrace snapshot: #{snapshot_path.inspect}"
      snapshot_json = convert_to_snapshot(data)
      FileUtils.mkdir_p(snapshot_dir)
      File.write(snapshot_path, JSON.pretty_generate(snapshot_json))
    elsif !File.exist?(snapshot_path)
      raise "Snapshot file not found: #{snapshot_path.inspect}"
    else
      snapshot_data = JSON.parse(File.read(snapshot_path))
      deep_snap_match(snapshot_data, data, [])
    end
  end

  def deep_snap_match(snapshot_data, data, path)
    case snapshot_data
    when String
      if snapshot_data.match(/\D/).nil? && data.match(/\D/).nil?
        # Ok
      else
        assert_equal snapshot_data.sub(" #1010", ""), data.sub(/ #\d+/, ""), "Match at #{path.join(".")}"
      end
    when Numeric
      assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
    when Hash
      assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
      extra_keys = snapshot_data.keys - data.keys
      extra_keys += data.keys - snapshot_data.keys
      assert_equal snapshot_data.keys.sort, data.keys.sort, "Match at #{path.join(".")} (#{extra_keys.map { |k| "#{k.inspect} => #{data[k].inspect}, snapshot: #{snapshot_data[k].inspect}"}.join(", ")})"
      snapshot_data.each do |k, v|
        deep_snap_match(v, data[k], path + [k])
      end
    when Array
      assert_equal(snapshot_data.class, data.class, "Match at #{path.join(".")}")
      snapshot_data.each_with_index do |snapshot_i, idx|
        data_i = data[idx]
        deep_snap_match(snapshot_i, data_i, path + [idx])
      end
    end
  end

  def convert_to_snapshot(value)
    case value
    when String
      if value.match(/\D/).nil?
        "10101010101010"
      else
        value.sub(/ #\d+/, " #1010")
      end
    when Numeric
      101010101010
    when Array
      value.map { |v| convert_to_snapshot(v) }
    when Hash
      h2 = {}
      value.each do |k, v|
        h2[k] = convert_to_snapshot(v)
      end
      h2
    when true, false, nil
      value
    else
      raise ArgumentError, "Unexpected JSON value: #{value}"
    end
  end
end
