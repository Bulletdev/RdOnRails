# frozen_string_literal: true

class AddAbandonmentFieldsToCarts < ActiveRecord::Migration[7.1]
  def change
    add_column :carts, :last_interaction_at, :datetime
    add_column :carts, :abandoned, :boolean, default: false

    # Set last_interaction_at to created_at for existing carts
    Cart.update_all('last_interaction_at = created_at')
  end
end
