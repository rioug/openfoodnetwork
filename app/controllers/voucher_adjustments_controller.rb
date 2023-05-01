# frozen_string_literal: true

class VoucherAdjustmentsController < BaseController
  include CablecarResponses

  def destroy
    @order = current_order

    @order.voucher_adjustments.find_by(id: params[:id])&.destroy

    render cable_ready: cable_car.replace(
      "#voucher-section",
      partial(
        "split_checkout/voucher_section",
        locals: { order: @order, voucher_adjustment: @order.voucher_adjustments.first }
      )
    )
  end
end
