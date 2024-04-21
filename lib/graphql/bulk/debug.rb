module GraphQL
  module Bulk
    class Debug
      class << self
        # rubocop:disable Rails/Output
        def print_string(result, prefix = "")
          puts "#{prefix}base: #{result[:base].delete("\n")}"
          puts "#{prefix}nested:"
          result[:nested].each do |nested|
            puts "#{prefix}\t ========= Result ======= "
            puts "#{prefix}\t path: #{nested[:path]}"
            puts "#{prefix}\t paginated: #{nested[:paginated].delete("\n")}"
            puts "#{prefix}\t unrolled:"
            nested[:unrolled].each do |u|
              puts "#{prefix}\t\t rollup_field: #{u[:rollup_field_name]}"
              print_string u[:queries], "#{prefix}\t\t "
            end
            puts "#{prefix}\t ========================"
          end
          # rubocop:enable Rails/Output
        end
      end
    end
  end
end
