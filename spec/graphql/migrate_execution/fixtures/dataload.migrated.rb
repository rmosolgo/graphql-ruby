# frozen_string_literal: true
module Types
  module Something
    include Types::BaseInterface

    field :dataload_assoc, Types::Thing

    def dataload_assoc
      dataload_association(:one)
    end

    field :dataload_object_1, Types::Thing, resolve_batch: true

    def self.dataload_object_1(objects, context)
      context.dataload_all(MySource, :two, objects)
    end

    def dataload_object_1
      context.dataloader.with(MySource, :two).load(object)
    end

    field :dataload_object_2, Types::Thing, resolve_batch: true

    def self.dataload_object_2(objects, context)
      context.dataload_all(Sources::Nested::MySource, objects.map(&:id))
    end

    def dataload_object_2
      dataload(Sources::Nested::MySource, object.id)
    end

    field :dataload_rec, Types::Thing

    def dataload_rec
      dataload_record(Something, object.something_id)
    end

    field :dataload_rec_2, Types::Thing

    def dataload_rec_2
      dataload_record(Something, object.something_name, find_by: :name)
    end

    field :dataload_complicated, Types::Thing

    def dataload_complicated
      a = 1 + 1
      dataload(Sources::SomeSource, :batch_key).load(a)
    end
  end
end
