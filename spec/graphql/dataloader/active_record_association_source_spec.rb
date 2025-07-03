# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::ActiveRecordAssociationSource do
  if testing_rails?
    class VulfpeckSchema < GraphQL::Schema
      class Album < GraphQL::Schema::Object
        field :name, String
      end
      class Band < GraphQL::Schema::Object
        field :albums, [Album] do
          argument :genre, String, required: false
          argument :reverse, Boolean, required: false, default_value: false
          argument :unscoped, Boolean, required: false, default_value: false
        end

        def albums(genre: nil, reverse:, unscoped:)
          if unscoped
            scope = nil
          else
            scope = ::Album
            if genre
              scope = scope.where(band_genre: genre)
            end

            scope = if reverse
              scope.order(name: :desc)
            else
              scope.order(:name)
            end
          end
          dataload_association(:albums, scope: scope)
        end
      end

      class Query < GraphQL::Schema::Object
        field :band, Band do
          argument :name, String
        end

        def band(name:)
          ::Band.find_by(name: name)
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    it "works with different scopes on the same object at runtime" do
      query_str = <<~GRAPHQL
        {
          band(name: "Vulfpeck") {
            allAlbums: albums {
              name
            }
            unscopedAlbums: albums(unscoped: true) {
              name
            }
            reverseAlbums: albums(reverse: true) {
              name
            }
            countryAlbums: albums(genre: "country") {
              name
            }
          }
        }
      GRAPHQL

      result = VulfpeckSchema.execute(query_str)
      assert_equal ["Mit Peck", "My First Car"], result["data"]["band"]["allAlbums"].map { |a| a["name"] }
      assert_equal ["Mit Peck", "My First Car"], result["data"]["band"]["unscopedAlbums"].map { |a| a["name"] }
      assert_equal ["My First Car", "Mit Peck"], result["data"]["band"]["reverseAlbums"].map { |a| a["name"] }
      assert_equal [], result["data"]["band"]["countryAlbums"]
    end

    it_dataloads "queries for associated records when the association isn't already loaded" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      log = with_active_record_log(colorize: false) do
        vulfpeck, chon = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
      end

      assert_includes log, '[["id", 1], ["id", 3]]'

      toms_story = ::Album.find(3)
      log = with_active_record_log(colorize: false) do
        vulfpeck, chon, toms_story_band = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
        assert_equal "Tom's Story", toms_story_band.name
      end

      assert_includes log, '[["id", 2]]'
    end

    it_dataloads "doesn't load records that are already cached by ActiveRecordSource" do |d|
      d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,3])

      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      toms_story = ::Album.find(3)

      log = with_active_record_log(colorize: false) do
        vulfpeck, chon, toms_story_band = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])
        assert_equal "Vulfpeck", vulfpeck.name
        assert_equal "Chon", chon.name
        assert_equal "Tom's Story", toms_story_band.name
      end

      assert_equal "", log
    end

    it_dataloads "warms the cache for ActiveRecordSource" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      toms_story = ::Album.find(3)
      d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band).load_all([my_first_car, homey, toms_story])

      log = with_active_record_log(colorize: false) do
        d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,3])
      end

      assert_equal "", log
    end

    it_dataloads "doesn't warm the cache when a scope is given" do |d|
      my_first_car = ::Album.find(2)
      homey = ::Album.find(4)
      summerteeth = ::Album.find(6)
      results = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band, ::Band.country).load_all([my_first_car, homey, summerteeth])
      assert_equal [nil, nil, ::Band.find(4)], results

      log = with_active_record_log(colorize: false) do
        d.with(GraphQL::Dataloader::ActiveRecordSource, Band).load_all([1,2,4])
      end

      assert_includes log, "SELECT \"bands\".* FROM \"bands\" WHERE \"bands\".\"id\" IN (?, ?, ?)  [[\"id\", 1], [\"id\", 2], [\"id\", 4]]"
    end

    it_dataloads "doesn't pause when the association is already loaded" do |d|
      source = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :band)
      assert_equal 0, source.results.size
      assert_equal 0, source.pending.size

      my_first_car = ::Album.find(2)
      vulfpeck = my_first_car.band

      vulfpeck2 = source.load(my_first_car)

      assert_equal vulfpeck, vulfpeck2

      assert_equal 0, source.results.size
      assert_equal 0, source.pending.size

      my_first_car.reload
      vulfpeck3 = source.load(my_first_car)
      assert_equal vulfpeck, vulfpeck3

      assert_equal 1, source.results.size
      assert_equal 0, source.pending.size
    end

    it_dataloads "raises an error with a non-existent association" do |d|
      my_first_car = ::Album.find(2)
      source = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :tour_bus)
      assert_raises ActiveRecord::AssociationNotFoundError do
        source.load(my_first_car)
      end
    end

    it_dataloads "works with polymorphic associations" do |d|
      wilco = ::Band.find(4)
      vulfpeck = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :thing).load(wilco)
      assert_equal ::Band.find(1), vulfpeck
    end

    it_dataloads "works with collection associations" do |d|
      wilco = ::Band.find(4)
      chon = ::Band.find(3)
      albums_by_band = nil
      log = with_active_record_log(colorize: false) do
        albums_by_band = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :albums).load_all([wilco, chon])
      end

      assert_equal [[6], [4, 5]], albums_by_band.map { |al| al.map(&:id) }
      assert_includes log, 'SELECT "albums".* FROM "albums" WHERE "albums"."band_id" IN (?, ?)  [["band_id", 4], ["band_id", 3]]'

      albums = nil
      log = with_active_record_log(colorize: false) do
        albums = d.with(GraphQL::Dataloader::ActiveRecordSource, Album).load_all([3,4,5,6])
      end

      assert_equal [3,4,5,6], albums.map(&:id)
      assert_includes log, 'WHERE "albums"."id" = ?  [["id", 3]]'
    end

    it_dataloads "works with collection associations with scope" do |d|
      wilco = ::Band.find(4)
      chon = ::Band.find(3)
      albums_by_band = nil
      one_month_ago = nil
      log = with_active_record_log(colorize: false) do
        one_month_ago = 1.month.ago.end_of_day
        albums_by_band_1 = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :albums, Album.where("created_at >= ?", one_month_ago)).request(wilco)
        albums_by_band_2 = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :albums, Album.where("created_at >= ?", one_month_ago)).request(chon)
        albums_by_band_3 = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :albums, Album.where("created_at <= ?", one_month_ago)).request(wilco)
        albums_by_band = [albums_by_band_1.load, albums_by_band_2.load, albums_by_band_3.load]
      end

      assert_equal [[6], [4, 5], []], albums_by_band.map { |al| al.map(&:id) }
      expected_log = if Rails::VERSION::STRING > "8"
        'SELECT "albums".* FROM "albums" WHERE (created_at >= ?) AND "albums"."band_id" IN (?, ?)'
      else
        'SELECT "albums".* FROM "albums" WHERE (created_at >= ' + one_month_ago.utc.strftime("'%Y-%m-%d %H:%M:%S.%6N'") + ') AND "albums"."band_id" IN (?, ?)'
      end

      assert_includes log, expected_log

      albums = nil
      log = with_active_record_log(colorize: false) do
        albums = d.with(GraphQL::Dataloader::ActiveRecordSource, Album).load_all([3,4,5,6])
      end

      assert_equal [3,4,5,6], albums.map(&:id)
      assert_includes log, 'WHERE "albums"."id" IN (?, ?, ?, ?)  [["id", 3], ["id", 4], ["id", 5], ["id", 6]]'
    end

    if Rails::VERSION::STRING > "7.1" # not supported in <7.1
      it_dataloads "loads with composite primary keys and warms the cache" do |d|
        my_first_car = ::Album.find(2)
        homey = ::Album.find(4)
        log = with_active_record_log(colorize: false) do
          vulfpeck, chon = d.with(GraphQL::Dataloader::ActiveRecordAssociationSource, :composite_band).load_all([my_first_car, homey])
          assert_equal "Vulfpeck", vulfpeck.name
          assert_equal "Chon", chon.name
        end

        assert_includes log, '[["name", "Vulfpeck"], ["name", "Chon"], ["genre", 0]]'


        log = with_active_record_log(colorize: false) do
          d.with(GraphQL::Dataloader::ActiveRecordSource, CompositeBand).load_all([["Vulfpeck", "rock"], ["Chon", :rock]])
        end

        assert_equal "", log
      end
    end
  end
end
