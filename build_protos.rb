files = Dir.glob("../perfetto/protos/perfetto/**/*.proto")
puts "Files: #{files.size}"
files.each do |filename|
  filename = filename.split("code/perfetto").last
  puts "  -> #{filename}"
  `protoc --ruby_out=lib/ --proto_path=../perfetto/ #{filename}`
end
