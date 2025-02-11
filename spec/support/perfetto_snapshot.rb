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
      cleaned_data = convert_to_snapshot(data)
      deep_snap_match(snapshot_data, cleaned_data, [])
    end
  end

  def deep_snap_match(snapshot_data, data, path)
    case snapshot_data
    when String
      assert_kind_of String, data, "Is String at #{path.join(".")}"
      if snapshot_data.match(/\D/).nil? && data.match(/\D/).nil?
        # Ok
      elsif BASE64_PATTERN.match?(snapshot_data)
        snapshot_data_decoded = Base64.decode64(snapshot_data)
        data_decoded = Base64.decode64(data)
        assert_equal snapshot_data_decoded, data_decoded, "Decoded match at #{path.join(".")}"
      else
        assert_equal snapshot_data, data, "Match at #{path.join(".")}"
      end
    when Numeric
      assert_kind_of Numeric, data, "Is numeric at #{path.join(".")}"
    when Hash
      assert_equal snapshot_data.class, data.class, "Match at #{path.join(".")}"
      extra_keys = snapshot_data.keys - data.keys
      extra_keys += data.keys - snapshot_data.keys
      assert_equal snapshot_data.keys.sort, data.keys.sort, "Match at #{path.join(".")} (#{extra_keys.map { |k| "#{k.inspect} => #{data[k].inspect}, snapshot: #{snapshot_data[k].inspect}"}.join(", ")})"
      snapshot_data.each do |k, v|
        next_data = data[k]
        if k == "debugAnnotations"
          next_data.sort_by! { |d| d["name"] }
        end
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

  BASE64_PATTERN = /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/

  def replace_ids(str)
    str.gsub(/ #\d+/, " #1010").split(/:0x[0-9a-z]+/).first
  end

  def convert_to_snapshot(value)
    case value
    when String
      if value.match(/\D/).nil?
        "10101010101010"
      elsif BASE64_PATTERN.match?(value)
        decoded_value = Base64.decode64(value)
        decoded_value = replace_ids(decoded_value)
        Base64.encode64(decoded_value)
      else
        replace_ids(value)
      end
    when Numeric
      101010101010
    when Array
      value.map { |v| convert_to_snapshot(v) }
    when Hash
      h2 = {}
      value.each do |k, v|
        if k == "debugAnnotations"
          v = v.sort_by { |d| d["name"] }
        end
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
