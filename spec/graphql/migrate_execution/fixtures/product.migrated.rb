# frozen_string_literal: true
module Types
  class Product < Types::BaseObject
    field :title, String
    field :description, String, method: :long_description
    field :price_in_cents, Integer, resolve_each: :price, resolver_method: :price do
      argument :coupon_code, String
    end

    def self.price(object, context, coupon_code:)
      (object.price * 100).round * Coupon.find(coupon_code)
    end

    def price(coupon_code:)
      self.class.price(object, context, coupon_code: coupon_code)
    end

    field :viewer_can_afford, Boolean, resolve_each: true

    def self.viewer_can_afford(object, context)
      context[:viewer].can_afford?(object)
    end

    def viewer_can_afford
      self.class.viewer_can_afford(object, context)
    end

    field :brand, Types::Brand, hash_key: "brand"

    field :trending, Boolean, resolve_static: true

    def self.trending(context)
      false
    end

    def trending
      self.class.trending(context)
    end

    field :on_sale, Boolean, resolve_static: :is_on_sale, resolver_method: :is_on_sale

    def self.is_on_sale(context)
      true
    end

    def is_on_sale
      self.class.is_on_sale(context)
    end

    field :diggable, String, dig: ["key1", "key2"]
    field :resolver_field, Integer, resolver: Resolvers::SomeResolver
  end
end
