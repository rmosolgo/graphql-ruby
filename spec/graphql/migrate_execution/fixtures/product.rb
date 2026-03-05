# frozen_string_literal: true
module Types
  class Product < Types::BaseObject
    field :title, String
    field :description, String, method: :long_description
    field :price_in_cents, Integer, resolver_method: :price do
      argument :coupon_code, String
    end

    def price(coupon_code:)
      (object.price * 100).round * Coupon.find(coupon_code)
    end

    field :viewer_can_afford, Boolean

    def viewer_can_afford
      context[:viewer].can_afford?(object)
    end

    field :brand, Types::Brand, hash_key: "brand"

    field :trending, Boolean

    def trending
      false
    end

    field :on_sale, Boolean, resolver_method: :is_on_sale

    def is_on_sale
      true
    end

    field :diggable, String, dig: ["key1", "key2"]
    field :resolver_field, Integer, resolver: Resolvers::SomeResolver
  end
end
