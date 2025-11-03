# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { 'Test Product' }
    price { 10.99 }
  end
end
