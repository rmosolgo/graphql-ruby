# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Dataloader::ActiveRecord do
    class HtmlColor < ActiveRecord::Base
    end

    HtmlColor.create!(name: "Bisque", hex: 0xFFE4C4)
    HtmlColor.create!(name: "Thistle", hex: 0xD8BFD8)
    HtmlColor.create!(name: "Gainsboro", hex: 0xDCDCDC)

    class DataloaderActiveRecordSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :color_by_hex, String, null: true do
          argument :hex, String, required: true
        end

        def color_by_hex(hex:)
          hex_int = hex.to_i(16)
          GraphQL::Dataloader::ActiveRecord.for(HtmlColor, column: "hex").load(hex_int).then { |c| c && c.name }
        end

        field :color_by_id_int, String, null: true do
          argument :id, Integer, required: true
        end

        def color_by_id_int(id:)
          GraphQL::Dataloader::ActiveRecord.load(HtmlColor, id).then { |c| c && c.name }
        end

        field :color_by_id_str, String, null: true do
          argument :id, ID, required: true
        end

        def color_by_id_str(id:)
          GraphQL::Dataloader::ActiveRecord.load(HtmlColor, id).then { |c| c && c.name }
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    def exec_query(*args, **kwargs)
      DataloaderActiveRecordSchema.execute(*args, **kwargs)
    end

    it "calls Model.where with columns and values" do
      res = nil
      log = []
      callback = ->(_name, _start, _end, _digest, query, *rest) { log << [query[:sql], query[:type_casted_binds]] }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        res = exec_query <<-GRAPHQL
        {
          bisque1: colorByHex(hex: "FFE4C4")
          bisque2: colorByIdInt(id: 1)
          bisque3: colorByIdStr(id: "1")
          thistle: colorByIdInt(id: 2)
          gainsboro: colorByIdStr(id: "3")
          missing: colorByIdInt(id: 99)
        }
        GRAPHQL
      end

      expected_data = {
        "bisque1" => "Bisque",
        "bisque2" => "Bisque",
        "bisque3" => "Bisque",
        "thistle" => "Thistle",
        "gainsboro" => "Gainsboro",
        "missing" => nil
      }

      assert_equal(expected_data, res["data"])

      expected_log = if Rails::VERSION::STRING < "4"
        nil
      elsif Rails::VERSION::STRING < "5"
        # Rails 4
        [
          ["SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"hex\" = 16770244", nil],
          ["SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"id\" IN (1, 2, 3, 99)", nil],
        ]
      elsif Rails::VERSION::STRING < "6"
        # Rails 5
        [
          [
            "SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"hex\" = $1",
            [16770244]
          ],
          [
            "SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"id\" IN ($1, $2, $3, $4)",
            [1, 2, 3, 99]
          ],
        ]
      else
        # Rails 6+
        [
          [
            "SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"hex\" = ?",
            [16770244]
          ],
          [
            "SELECT \"html_colors\".* FROM \"html_colors\" WHERE \"html_colors\".\"id\" IN (?, ?, ?, ?)",
            [1, 2, 3, 99]
          ],
        ]
      end

      if expected_log
        assert_equal expected_log, log
      end
    end
  end
end
