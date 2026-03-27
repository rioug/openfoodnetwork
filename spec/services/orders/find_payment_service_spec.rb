# frozen_string_literal: true

RSpec.describe Orders::FindPaymentService do
  subject(:finder) { described_class.new(order) }
  let(:order) { create(:order_with_distributor) }

  describe "#last_pending_payment" do
    context "when order has several non pending payments" do
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }
      let!(:complete_payment) { create(:payment, :completed, order:) }

      it "returns nil" do
        expect(finder.last_pending_payment).to be nil
      end
    end

    context "when order has a pending payment and a non pending payment" do
      let!(:processing_payment) { create(:payment, order:, state: 'processing') }
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }

      it "returns the pending payment" do
        # a payment in the processing state is a pending payment
        expect(finder.last_pending_payment).to eq processing_payment
      end

      context "and an extra last pending payment" do
        let!(:pending_payment) { create(:payment, order:, state: 'pending') }

        it "returns the pending payment" do
          expect(finder.last_pending_payment).to eq pending_payment
        end
      end
    end
  end

  describe "#last_payment" do
    context "when order has several non pending payments" do
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }
      let!(:complete_payment) { create(:payment, :completed, order:) }

      it "returns the last payment" do
        expect(finder.last_payment).to eq complete_payment
      end
    end

    context "when order has a pending payment and a non pending payment" do
      let!(:processing_payment) { create(:payment, order:, state: 'processing') }
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }

      it "returns the last payment" do
        expect(finder.last_payment).to eq failed_payment
      end

      context "and an extra last pending payment" do
        let!(:pending_payment) { create(:payment, order:, state: 'pending') }

        it "returns the last payment" do
          expect(finder.last_payment).to eq pending_payment
        end
      end
    end
  end
end
