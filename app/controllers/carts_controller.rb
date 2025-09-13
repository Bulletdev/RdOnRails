class CartsController < ApplicationController
  before_action :ensure_cart, only: [:show, :add_item, :destroy_item]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /cart
  def show
    render json: @cart.to_json_response
  end

  # POST /cart
  def create
    @cart = find_or_create_cart
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    if quantity <= 0
      render json: { error: 'Quantity must be greater than 0' }, status: :unprocessable_entity
      return
    end

    @cart.add_product(product, quantity)
    session[:cart_id] = @cart.id

    render json: @cart.to_json_response, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  # POST /cart/add_item
  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    if quantity <= 0
      render json: { error: 'Quantity must be greater than 0' }, status: :unprocessable_entity
      return
    end

    @cart.add_product(product, quantity)

    render json: @cart.to_json_response
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  # DELETE /cart/:product_id
  def destroy_item
    product = Product.find(params[:product_id])
    
    unless @cart.remove_product(product)
      render json: { error: 'Product not found in cart' }, status: :not_found
      return
    end

    render json: @cart.to_json_response
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  private

  def find_or_create_cart
    if session[:cart_id].present?
      cart = Cart.find_by(id: session[:cart_id])
      return cart if cart&.persisted? && !cart.abandoned?
    end

    Cart.create!
  end

  def ensure_cart
    @cart = find_or_create_cart
    session[:cart_id] = @cart.id
  end

  def record_not_found
    render json: { error: 'Resource not found' }, status: :not_found
  end
end
