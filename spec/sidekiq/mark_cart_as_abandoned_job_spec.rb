require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    let!(:active_cart) { create(:cart, last_interaction_at: 1.hour.ago, abandoned: false) }
    let!(:inactive_cart) { create(:cart, last_interaction_at: 4.hours.ago, abandoned: false) }
    let!(:already_abandoned_cart) do
      cart = create(:cart, last_interaction_at: 5.hours.ago, abandoned: true)
      cart.update_column(:updated_at, 2.days.ago)
      cart
    end
    let!(:old_abandoned_cart) do
      cart = create(:cart, last_interaction_at: 10.hours.ago, abandoned: true)
      cart.update_column(:updated_at, 8.days.ago)
      cart
    end

    before do
      # Create some cart items to make carts more realistic
      product = create(:product)
      create(:cart_item, cart: active_cart, product: product)
      create(:cart_item, cart: inactive_cart, product: product)
      create(:cart_item, cart: already_abandoned_cart, product: product)
      create(:cart_item, cart: old_abandoned_cart, product: product)
    end

    it 'marks inactive carts as abandoned' do
      expect {
        described_class.new.perform
      }.to change { inactive_cart.reload.abandoned }.from(false).to(true)
    end

    it 'does not mark active carts as abandoned' do
      expect {
        described_class.new.perform
      }.not_to change { active_cart.reload.abandoned }
    end

    it 'removes old abandoned carts' do
      expect {
        described_class.new.perform
      }.to change(Cart, :count).by(-1)
      
      expect { old_abandoned_cart.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not remove recently abandoned carts' do
      expect {
        described_class.new.perform
      }.not_to change { already_abandoned_cart.reload }
    end

    it 'logs the execution' do
      expect(Rails.logger).to receive(:info).with("Starting abandoned cart cleanup job")
      expect(Rails.logger).to receive(:info).with(/Marked \d+ carts as abandoned/)
      expect(Rails.logger).to receive(:info).with(/Removed \d+ old abandoned carts/)
      expect(Rails.logger).to receive(:info).with("Completed abandoned cart cleanup job")

      described_class.new.perform
    end
  end
end
