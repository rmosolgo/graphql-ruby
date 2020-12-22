# frozen_string_literal: true
require "spec_helper"

# Rails 3 doesn't have type_for_attribute
if testing_rails? && ActiveRecord::Base.respond_to?(:type_for_attribute)
  describe GraphQL::Dataloader::ActiveRecordAssociation do
    class Artist < ActiveRecord::Base
      has_many :albums
    end

    class Album < ActiveRecord::Base
      belongs_to :artist
    end

    the_shins = Artist.create!(name: "The Shins")
    the_shins.albums.create!(name: "Oh, Inverted World")
    the_shins.albums.create!(name: "Chutes Too Narrow")
    the_shins.albums.create!(name: "Wincing the Night Away")

    mt_joy = Artist.create!(name: "Mt. Joy")
    mt_joy.albums.create!(name: "Mt. Joy")
    mt_joy.albums.create!(name: "Rearrange Us")

    the_extraordinaires = Artist.create(name: "The Extraordinaires")
    the_extraordinaires.albums.create!(name: "Ribbons of War")
    the_extraordinaires.albums.create!(name: "Short Stories")
    the_extraordinaires.albums.create!(name: "Electric and Benevolent")
    the_extraordinaires.albums.create!(name: "Home Sweet Home")

    class DataloaderActiveRecordAssociationSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :artist_album_count, Integer, null: true do
          argument :album_name, String, required: true
        end

        def artist_album_count(album_name:)
          GraphQL::Dataloader::ActiveRecord.for(Album, column: "name").load(album_name).then do |album|
            # IRL This could be done better using `album.artist_id`, but this is a nice way to test the belongs-to association
            album && GraphQL::Dataloader::ActiveRecordAssociation.load(Album, :artist, album).then do |artist|
              artist && artist.albums.count
            end
          end
        end

        field :artist_name, String, null: true do
          argument :album_name, String, required: true
        end

        def artist_name(album_name:)
          GraphQL::Dataloader::ActiveRecord.for(Album, column: "name").load(album_name).then do |album|
            album && GraphQL::Dataloader::ActiveRecordAssociation.load(Album, :artist, album).then(&:name)
          end
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    def exec_query(*args, **kwargs)
      DataloaderActiveRecordAssociationSchema.execute(*args, **kwargs)
    end

    it "batches calls for belongs-tos" do
      res = nil
      log = []
      callback = ->(_name, _start, _end, _digest, query, *rest) { log << [query[:sql], query[:type_casted_binds]] }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        res = exec_query <<-GRAPHQL
        {
          ext1: artistAlbumCount(albumName: "Short Stories")
          shins1: artistName(albumName: "Wincing the Night Away")
          mtJoy1: artistName(albumName: "Rearrange Us")
          shins2: artistName(albumName: "Chutes Too Narrow")
          miss1: artistName(albumName: "Tom's Story")
          shins3: artistAlbumCount(albumName: "Oh, Inverted World")
        }
        GRAPHQL
      end

      expected_data = {
        "ext1" => 4,
        "shins1" => "The Shins",
        "mtJoy1" => "Mt. Joy",
        "shins2" => "The Shins",
        "miss1" => nil,
        "shins3" => 3,
      }

      assert_equal(expected_data, res["data"])
      expected_log = if Rails::VERSION::STRING < "5"
        # Rails 4
        [
          ["SELECT \"albums\".* FROM \"albums\" WHERE \"albums\".\"name\" IN ('Short Stories', 'Wincing the Night Away', 'Rearrange Us', 'Chutes Too Narrow', 'Tom''s Story', 'Oh, Inverted World')", nil],
          ["SELECT \"artists\".* FROM \"artists\" WHERE \"artists\".\"id\" IN (3, 1, 2)",nil],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = ?", nil],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = ?", nil],
        ]
      elsif Rails::VERSION::STRING < "6"
        # Rails 5
        [
          [
            "SELECT \"albums\".* FROM \"albums\" WHERE \"albums\".\"name\" IN ($1, $2, $3, $4, $5, $6)",
            ["Short Stories", "Wincing the Night Away", "Rearrange Us", "Chutes Too Narrow", "Tom's Story", "Oh, Inverted World"]
          ],
          ["SELECT \"artists\".* FROM \"artists\" WHERE \"artists\".\"id\" IN ($1, $2, $3)", [3, 1, 2]],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = $1", [3]],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = $1", [1]],
        ]
      else
        # Rails 6 +
        [
          [
            "SELECT \"albums\".* FROM \"albums\" WHERE \"albums\".\"name\" IN (?, ?, ?, ?, ?, ?)",
            ["Short Stories", "Wincing the Night Away", "Rearrange Us", "Chutes Too Narrow", "Tom's Story", "Oh, Inverted World"]
          ],
          ["SELECT \"artists\".* FROM \"artists\" WHERE \"artists\".\"id\" IN (?, ?, ?)", [3, 1, 2]],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = ?", [3]],
          ["SELECT COUNT(*) FROM \"albums\" WHERE \"albums\".\"artist_id\" = ?", [1]],
        ]
      end

      if expected_log
        assert_equal expected_log, log, "It has the expected queries on Rails #{Rails::VERSION::STRING}"
      end
    end
  end
end
