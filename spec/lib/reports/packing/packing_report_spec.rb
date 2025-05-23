# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Packing Reports" do
  describe "fetching orders" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle) }
    let(:order) {
      create(:completed_order_with_totals, order_cycle:, distributor:,
                                           line_items_count: 0)
    }
    let(:line_item) { build(:line_item_with_shipment) }
    let(:user) { create(:admin_user) }
    let(:params) { {} }

    let(:report_data) { subject.report_data.as_json }
    let(:report_contents) { subject.report_data.rows.flatten }
    let(:row_count) { subject.report_data.rows.count }

    subject { Reporting::Reports::Packing::Customer.new user, { q: params } }

    before do
      order.line_items << line_item
      order.finalize!
    end

    context "as a site admin" do
      let(:cancelled_order) { create(:completed_order_with_totals, line_items_count: 0) }
      let(:line_item2) { build(:line_item_with_shipment) }

      before do
        cancelled_order.line_items << line_item2
        cancelled_order.finalize!
        cancelled_order.cancel!
      end

      it "fetches line items for completed orders" do
        expect(report_contents).to include line_item.product.name
      end

      it "does not fetch line items for cancelled orders" do
        expect(report_contents).not_to include line_item2.product.name
      end
    end

    context "as a manager of a supplier" do
      let!(:user) { create(:user) }
      let(:supplier1) { create(:supplier_enterprise) }
      let(:supplier2) { create(:supplier_enterprise) }
      let(:order2) {
        create(:completed_order_with_totals, distributor:,
                                             bill_address: create(:address),
                                             ship_address: create(:address))
      }
      let(:line_item2) {
        build(
          :line_item_with_shipment,
          variant: create(
            :variant, supplier: supplier1, product: create(:simple_product, name: "visible")
          )
        )
      }
      let(:line_item3) {
        build(
          :line_item_with_shipment,
          variant: create(
            :variant, supplier: supplier2, product: create(:simple_product, name: "not visible")
          )
        )
      }

      before do
        order2.line_items << line_item2
        order2.line_items << line_item3
        order2.finalize!
        supplier1.enterprise_roles.create!(user:)
      end

      context "which has not granted P-OC to the distributor" do
        it "does not show line items supplied by my producers" do
          expect(row_count).to eq 0
        end
      end

      context "which has granted P-OC to the distributor" do
        before do
          create(:enterprise_relationship, parent: supplier1, child: distributor,
                                           permissions_list: [:add_to_order_cycle])
        end

        it "shows line items supplied by my producers, with names and contacts hidden" do
          expect(report_contents).to include line_item2.product.name
          row = report_data.first
          expect(row["customer_code"]).to eq '< Hidden >'
          expect(row["first_name"]).to eq '< Hidden >'
          expect(row["last_name"]).to eq '< Hidden >'
          expect(row["phone"]).to eq '< Hidden >'
        end

        context "where the distributor allows suppliers to see customer names" do
          let(:distributor) {
            create(:distributor_enterprise, show_customer_names_to_suppliers: true)
          }

          it "shows line items supplied by my producers, with names and contacts shown" do
            row = report_data.first
            expect(row["customer_code"]).to eq order2.customer.code
            expect(row["first_name"]).to eq order2.bill_address.firstname
            expect(row["last_name"]).to eq order2.bill_address.lastname
            expect(row["phone"]).to eq '< Hidden >'
          end
        end

        context "where the distributor allows suppliers to see customer contact details" do
          let(:distributor) {
            create(:distributor_enterprise, show_customer_contacts_to_suppliers: true)
          }

          it "shows line items supplied by my producers, with names and contacts shown" do
            row = report_data.first
            expect(row["first_name"]).to eq '< Hidden >'
            expect(row["last_name"]).to eq '< Hidden >'
            expect(row["phone"]).to eq order2.bill_address.phone
          end
        end

        context "where an order contains items from multiple suppliers" do
          it "only shows line items the current user supplies" do
            expect(report_contents).to include line_item2.product.name
            expect(report_contents).not_to include line_item3.product.name
          end
        end
      end
    end

    context "as a manager of a distributor" do
      let!(:user) { create(:user) }
      let(:distributor2) { create(:distributor_enterprise) }
      let(:order3) {
        create(:completed_order_with_totals, distributor: distributor2,
                                             line_items_count: 0)
      }
      let(:line_item3) { build(:line_item_with_shipment) }

      before do
        order3.line_items << line_item3
        order3.finalize!
        distributor.enterprise_roles.create!(user:)
      end

      it "only shows line items distributed by enterprises managed by the current user" do
        expect(report_contents).to include line_item.product.name
        expect(report_contents).not_to include line_item3.product.name
      end

      context "filtering results" do
        let(:order_cycle2) { create(:simple_order_cycle) }
        let(:order4) {
          create(:completed_order_with_totals, distributor:, order_cycle: order_cycle2,
                                               line_items_count: 0)
        }
        let(:line_item4) { build(:line_item_with_shipment) }

        before do
          order4.line_items << line_item4
          order4.finalize!
          line_item4.variant.update(supplier: create(:supplier_enterprise))
        end

        context "filtering by order cycle" do
          let(:params) { { order_cycle_id_in: [order_cycle.id] } }

          it "only shows results from the selected order cycle" do
            expect(report_contents).to include line_item.product.name
            expect(report_contents).not_to include line_item4.product.name
          end
        end

        context "filtering by supplier" do
          let(:params) { { supplier_id_in: [line_item.supplier.id] } }

          it "only shows results from the selected supplier" do
            expect(report_contents).to include line_item.product.name
            expect(report_contents).not_to include line_item4.product.name
          end
        end
      end
    end

    describe "ordering and grouping" do
      let(:distributor2) { create(:distributor_enterprise) }
      let(:order2) {
        create(:completed_order_with_totals, order_cycle:, distributor: distributor2,
                                             line_items_count: 2)
      }

      before do
        order2.finalize!
      end

      it "groups and orders by distributor and order" do
        expect(subject.report_data.rows.map(&:first)).to eq(
          [order.distributor.name, order2.distributor.name, order2.distributor.name]
        )
      end
    end

    context "shipping method and shipment state" do
      it "includes shipping method and shipment state" do
        expect(report_data.first["shipping_method"]).to eq order.shipping_method.name
        expect(report_data.first["shipment_state"]).to eq order.shipment_state
      end
    end
  end
end
