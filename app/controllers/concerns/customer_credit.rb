# frozen_string_literal: true

module CustomerCredit
  extend ActiveSupport::Concern

  def calculate_credit(order)
    credit_payment_method = Spree::PaymentMethod.customer_credit
    order.payments.where(payment_method: credit_payment_method).sum(:amount)
  end
end
