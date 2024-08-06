# frozen_string_literal: true

module Admin
  module ProductsHelper
    def product_image_form_path(product)
      if product.image.present?
        edit_admin_product_image_path(product.id, product.image.id)
      else
        new_admin_product_image_path(product.id)
      end
    end

    def unit_value_with_description(variant)
      return "" if variant.unit_value.nil?

      scaled_unit_value = variant.unit_value / (variant.variant_unit_scale || 1)
      precised_unit_value = number_with_precision(
        scaled_unit_value,
        precision: nil,
        strip_insignificant_zeros: true
      )

      [precised_unit_value, variant.unit_description].compact_blank.join(" ")
    end
  end
end
