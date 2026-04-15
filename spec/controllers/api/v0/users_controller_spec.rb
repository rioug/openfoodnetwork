# frozen_string_literal: true

module Api
  RSpec.describe V0::UsersController do
    include AuthenticationHelper

    let(:user) { create(:user) }

    describe "#accept_terms_of_service" do
      context "as an authenticated user" do
        before do
          allow(controller).to receive(:spree_current_user) { user }
        end

        it "records that the user has accepted the Terms of Service" do
          expect {
            spree_post :accept_terms_of_service
            user.reload
          }.to change { user.terms_of_service_accepted_at }
          expect(response).to have_http_status :ok
        end

        it "updates terms_of_service_accepted_at to the current time" do
          freeze_time do
            spree_post :accept_terms_of_service
            user.reload
            expect(user.terms_of_service_accepted_at).to eq(DateTime.now)
          end
        end
      end

      context "as an anonymous user" do
        before do
          allow(controller).to receive(:spree_current_user) { nil }
        end

        it "returns unauthorized" do
          spree_post :accept_terms_of_service
          expect(response).to have_http_status :unauthorized
        end
      end
    end
  end
end
