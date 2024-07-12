# frozen_string_literal: false

require 'spec_helper'

RSpec.describe Spree::Variant do
  # This method is defined in app/models/concerns/variant_stock.rb.
  # There is a separate spec for that concern but here I want to test
  # the interplay of Spree::Variant and VariantOverride.
  #
  # A variant can be scoped to a hub which means that all stock methods
  # like this one get overridden. Future calls to `variant.move` are then
  # handled by the ScopeVariantToHub module which may call the
  # VariantOverride.
  describe "#move" do
    subject(:variant) { create(:variant, on_hand: 5) }

    it "changes stock" do
      expect { variant.move(-2) }.to change { variant.on_hand }.from(5).to(3)
    end

    it "reduces stock even when on demand" do
      variant.on_demand = true

      expect { variant.move(-2) }.to change { variant.on_hand }.from(5).to(3)
    end

    it "rejects negative stock" do
      expect { variant.move(-7) }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Count on hand must be greater than or equal to 0"
      )
    end

    describe "with VariantOverride" do
      subject(:hub_variant) {
        Spree::Variant.find(variant.id).tap { |v| scoper.scope(v) }
      }
      let(:override) {
        VariantOverride.create!(
          variant:,
          hub: create(:distributor_enterprise),
          count_on_hand: 7,
          on_demand: false,
        )
      }
      let(:scoper) { OpenFoodNetwork::ScopeVariantToHub.new(override.hub) }

      it "changes stock only on the variant override" do
        expect {
          hub_variant.move(-3)
          override.reload
        }
          .to change { override.count_on_hand }.from(7).to(4)
          .and change { hub_variant.on_hand }.from(7).to(4)
          .and change { variant.on_hand }.by(0)
      end

      it "reduces stock when on demand" do
        pending "VariantOverride allowing stock with on_demand"

        override.update!(on_demand: true, count_on_hand: 7)

        expect {
          hub_variant.move(-3)
          override.reload
        }
          .to change { override.count_on_hand }.from(7).to(4)
          .and change { hub_variant.on_hand }.from(7).to(4)
          .and change { variant.on_hand }.by(0)
      end

      it "doesn't prevent negative stock" do
        # VariantOverride relies on other stock checks during checkout. :-(
        expect {
          hub_variant.move(-8)
          override.reload
        }
          .to change { override.count_on_hand }.from(7).to(-1)
          .and change { hub_variant.on_hand }.from(7).to(-1)
          .and change { variant.on_hand }.by(0)

        # The update didn't run validations and now it's invalid:
        expect(override).not_to be_valid
      end

      it "doesn't fail on negative stock when on demand" do
        pending "https://github.com/openfoodfoundation/openfoodnetwork/issues/12586"

        override.update!(on_demand: true, count_on_hand: nil)

        expect {
          hub_variant.move(-8)
          override.reload
        }
          .to change { override.count_on_hand }.from(7).to(-1)
          .and change { hub_variant.on_hand }.from(7).to(-1)
          .and change { variant.on_hand }.by(0)
      end
    end
  end
end
