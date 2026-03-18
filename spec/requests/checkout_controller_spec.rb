# frozen_string_literal: true

RSpec.describe CheckoutController do
  include_context "session helper"

  let(:user) { order.user }
  let(:address) { create(:address) }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:,)
  }
  let(:shipping_method) { distributor.shipping_methods.first }

  before do
    exchange.variants << order.line_items.first.variant
    session_hash[:order_id] = order.id
    sign_in user
  end

  describe "PUT /checkout/:step" do
    let(:params) { { step: "payment" } }

    context "with payment step" do
      before do
        order.bill_address = address
        order.ship_address = address
        order.select_shipping_method shipping_method.id
        Orders::WorkflowService.new(order).advance_to_payment
      end

      context "with an order paid with customer credit" do
        let(:credit_payment_method) { create(:customer_credit_payment_method) }

        before do
          ## Add payment with credit
          payment = order.payments.create!(
            amount: order.total, payment_method: credit_payment_method, state: "checkout"
          )
        end

        it "allows proceeding to confirmation" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
        end
      end
    end
  end
end
