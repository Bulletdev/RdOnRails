require 'rails_helper'

RSpec.describe CartItem, type: :model do
  let(:cart) { create(:cart) }
  let(:product) { create(:product, price: 15.50) }
  let(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 3) }

  describe 'associations' do
    it 'belongs to cart' do
      expect(cart_item.cart).to eq(cart)
    end

    it 'belongs to product' do
      expect(cart_item.product).to eq(product)
    end
  end

  describe 'validations' do
    it 'validates presence of quantity' do
      cart_item = build(:cart_item, quantity: nil)
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:quantity]).to include("can't be blank")
    end

    it 'validates quantity is greater than 0' do
      cart_item = build(:cart_item, quantity: 0)
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:quantity]).to include("must be greater than 0")
    end

    it 'validates quantity is a number' do
      cart_item = build(:cart_item, quantity: 'invalid')
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:quantity]).to include("is not a number")
    end
    
    it 'validates uniqueness of product per cart' do
      create(:cart_item, cart: cart, product: product)
      duplicate_item = build(:cart_item, cart: cart, product: product)
      
      expect(duplicate_item).not_to be_valid
      expect(duplicate_item.errors[:cart_id]).to include('has already been taken')
    end

    it 'allows same product in different carts' do
      another_cart = create(:cart)
      create(:cart_item, cart: cart, product: product)
      duplicate_item = build(:cart_item, cart: another_cart, product: product)
      
      expect(duplicate_item).to be_valid
    end
  end

  describe '#total_price' do
    it 'calculates total price correctly' do
      expect(cart_item.total_price).to eq(46.50)  # 3 * 15.50
    end

    it 'updates when quantity changes' do
      cart_item.update(quantity: 5)
      expect(cart_item.total_price).to eq(77.50)  # 5 * 15.50
    end

    it 'updates when product price changes' do
      product.update(price: 20.00)
      expect(cart_item.total_price).to eq(60.00)  # 3 * 20.00
    end
  end
end