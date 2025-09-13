class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0, allow_nil: true

  before_create :set_initial_interaction_time
  before_create :set_initial_total_price
  before_save :ensure_valid_total_price

  def calculate_total_price
    cart_items.sum { |item| item.total_price }
  end

  def update_total_price!
    update!(total_price: calculate_total_price)
  end

  def add_product(product, quantity)
    cart_item = cart_items.find_by(product: product)
    
    if cart_item
      cart_item.update!(quantity: cart_item.quantity + quantity)
    else
      cart_items.create!(product: product, quantity: quantity)
    end
    
    update_interaction_time!
    update_total_price!
  end

  def remove_product(product)
    cart_item = cart_items.find_by(product: product)
    return false unless cart_item
    
    cart_item.destroy!
    update_interaction_time!
    update_total_price!
    true
  end

  def update_interaction_time!
    touch(:last_interaction_at)
  end

  def mark_as_abandoned
    return false if abandoned?
    return false unless inactive_for?(3.hours)

    update!(abandoned: true)
    true
  end

  def remove_if_abandoned
    return false unless abandoned? && abandoned_for?(7.days)

    destroy!
    true
  end

  def abandoned?
    abandoned
  end

  def products_json
    cart_items.includes(:product).map do |item|
      {
        id: item.product.id,
        name: item.product.name,
        quantity: item.quantity,
        unit_price: item.product.price,
        total_price: item.total_price
      }
    end
  end

  def to_json_response
    {
      id: id,
      products: products_json,
      total_price: total_price
    }
  end

  private

  def set_initial_interaction_time
    self.last_interaction_at = Time.current if last_interaction_at.nil?
  end

  def set_initial_total_price
    self.total_price = 0.0
  end

  def ensure_valid_total_price
    self.total_price = 0.0 if total_price.nil?
  end

  def inactive_for?(duration)
    last_interaction_at && last_interaction_at < duration.ago
  end

  def abandoned_for?(duration)
    abandoned? && updated_at < duration.ago
  end
end
