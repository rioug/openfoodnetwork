# frozen_string_literal: true

require 'open_food_network/address_finder'

module Api
  module Admin
    class UserSerializer < ActiveModel::Serializer
      attributes :id, :email, :confirmed

      def confirmed
        object.confirmed?
      end
    end
  end
end
