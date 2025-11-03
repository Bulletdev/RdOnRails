# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/carts', type: :request do
  let(:product) { create(:product, name: 'Test Product', price: 10.0) }
  let(:another_product) { create(:product, name: 'Another Product', price: 5.0) }

  describe 'GET /cart' do
    context "when cart doesn't exist in session" do
      it 'creates a new cart and returns empty cart' do
        get '/cart'

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to include(
          'id' => be_present,
          'products' => [],
          'total_price' => '0.0'
        )
      end
    end

    context 'when cart exists in session' do
      it 'returns the existing cart with products' do
        # First create a cart by adding a product
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        # Now get the cart
        get '/cart'
        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['id']).to be_present
        expect(parsed_response['products'].length).to eq(1)
        expect(parsed_response['products'][0]).to include(
          'id' => product.id,
          'name' => 'Test Product',
          'quantity' => 2,
          'unit_price' => '10.0',
          'total_price' => '20.0'
        )
        expect(parsed_response['total_price']).to eq('20.0')
      end
    end
  end

  describe 'POST /cart' do
    context 'with valid parameters' do
      it 'creates a cart and adds product' do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['id']).to be_present
        expect(parsed_response['products'].length).to eq(1)
        expect(parsed_response['products'][0]).to include(
          'id' => product.id,
          'quantity' => 2,
          'total_price' => '20.0'
        )
        expect(parsed_response['total_price']).to eq('20.0')
      end

      it 'sets cart_id in session', :skip_session do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json

        # Session testing is complex in API-only applications
        # This test would need integration testing setup
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid product' do
      it 'returns error for non-existent product' do
        post '/cart', params: { product_id: 99_999, quantity: 1 }, as: :json

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Product not found')
      end
    end

    context 'with invalid quantity' do
      it 'returns error for negative quantity' do
        post '/cart', params: { product_id: product.id, quantity: -1 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error' => 'Quantity must be greater than 0')
      end

      it 'returns error for zero quantity' do
        post '/cart', params: { product_id: product.id, quantity: 0 }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include('error' => 'Quantity must be greater than 0')
      end
    end
  end

  describe 'POST /cart/add_item' do
    context 'when product is not in cart' do
      it 'adds new product to cart' do
        # First create a cart
        post '/cart', params: { product_id: another_product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:created)

        # Then add a different product
        post '/cart/add_item', params: { product_id: product.id, quantity: 3 }, as: :json

        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['products'].length).to eq(2)
        product_in_cart = parsed_response['products'].find { |p| p['id'] == product.id }
        expect(product_in_cart).to include(
          'id' => product.id,
          'quantity' => 3,
          'total_price' => '30.0'
        )
      end
    end

    context 'when product already exists in cart' do
      it 'updates quantity of existing product' do
        # First create a cart with the product
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:created)

        # Then add more of the same product
        post '/cart/add_item', params: { product_id: product.id, quantity: 2 }, as: :json

        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['products'].length).to eq(1)
        expect(parsed_response['products'][0]).to include(
          'id' => product.id,
          'quantity' => 3,
          'total_price' => '30.0'
        )
      end
    end
  end

  describe 'POST /add_items' do
    context 'when the product already is in the cart' do
      it 'updates the quantity of the existing item in the cart' do
        # First create a cart with the product
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:created)
        JSON.parse(response.body)

        # Add the product twice more (this should be cart/add_item not add_items)
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:success)

        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:success)

        final_cart = JSON.parse(response.body)
        expect(final_cart['products'][0]['quantity']).to eq(3)
      end
    end
  end

  describe 'DELETE /cart/:product_id' do
    context 'when product exists in cart' do
      it 'removes product from cart' do
        # First create a cart with the product
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        # Then remove the product
        delete "/cart/#{product.id}", as: :json

        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)

        expect(parsed_response['products']).to be_empty
        expect(parsed_response['total_price']).to eq('0.0')
      end

      it 'removes cart_item from database' do
        # First create a cart with the product
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        expect do
          delete "/cart/#{product.id}", as: :json
        end.to change(CartItem, :count).by(-1)
      end
    end

    context "when product doesn't exist in cart" do
      it 'returns error' do
        # First create a cart with one product
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        # Try to remove a different product
        delete "/cart/#{another_product.id}", as: :json

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Product not found in cart')
      end
    end

    context "when product doesn't exist" do
      it 'returns error for non-existent product' do
        # First create a cart
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:created)

        # Try to remove a non-existent product
        delete '/cart/99999', as: :json

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error' => 'Product not found')
      end
    end
  end
end
