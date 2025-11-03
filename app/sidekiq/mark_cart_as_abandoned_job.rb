# frozen_string_literal: true

class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    Rails.logger.info 'Starting abandoned cart cleanup job'

    mark_inactive_carts_as_abandoned
    remove_old_abandoned_carts

    Rails.logger.info 'Completed abandoned cart cleanup job'
  end

  private

  def mark_inactive_carts_as_abandoned
    # Mark carts as abandoned if inactive for more than 3 hours
    inactive_carts = Cart.where(abandoned: false)
                         .where('last_interaction_at < ?', 3.hours.ago)

    marked_count = 0
    inactive_carts.find_each do |cart|
      marked_count += 1 if cart.mark_as_abandoned
    end

    Rails.logger.info "Marked #{marked_count} carts as abandoned"
  end

  def remove_old_abandoned_carts
    # Remove carts that have been abandoned for more than 7 days
    old_abandoned_carts = Cart.where(abandoned: true)
                              .where('updated_at < ?', 7.days.ago)

    removed_count = 0
    old_abandoned_carts.find_each do |cart|
      removed_count += 1 if cart.remove_if_abandoned
    end

    Rails.logger.info "Removed #{removed_count} old abandoned carts"
  end
end
