# frozen_string_literal: true

module Api
  module V0
    class UsersController < Api::V0::BaseController
      skip_authorization_check only: [:accept_terms_of_service]

      # Records that the current user has accepted the Terms of Service.
      # Called during enterprise registration when the user checks the ToS checkbox.
      def accept_terms_of_service
        return unauthorized unless current_api_user.persisted?

        current_api_user.update!(terms_of_service_accepted_at: DateTime.now)

        render json: {}, status: :ok
      end
    end
  end
end
