# frozen_string_literal: false

class Voucher < ApplicationRecord
  acts_as_paranoid

  belongs_to :enterprise, optional: false

  has_many :adjustments,
           as: :originator,
           class_name: 'Spree::Adjustment',
           dependent: :nullify

  validates :code, presence: true, uniqueness: { scope: :enterprise_id }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  def display_value
    Spree::Money.new(amount)
  end

  # Ideally we would use `include CalculatedAdjustments` to be consistent with other adjustments,
  # but vouchers have complicated calculation so we can't easily use Spree::Calculator. We keep
  # the same method to stay as consistent as possible.
  #
  def create_adjustment(label, order)
    adjustment_attributes = {
      amount: 0, # Amount is updated by VoucherAdjustmentsService below
      originator: self,
      order: order,
      label: label,
      mandatory: false,
      state: "open",
      tax_category: nil
    }

    adjustment = order.adjustments.new(adjustment_attributes)

    if adjustment.save
      VoucherAdjustmentsService.new(order).update
      order.update_totals_and_states
    end

    adjustment
  end

  # We limit adjustment to the maximum amount needed to cover the order, ie if the voucher
  # covers more than the order.total we only need to create an adjustment covering the order.total
  def compute_amount(order)
    -amount.clamp(0, order.pre_discount_total)
  end
end
