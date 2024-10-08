# frozen_string_literal: true

module PermittedAttributes
  class Product
    def self.attributes
      [
        :id, :name, :description, :price,
        :variant_unit, :variant_unit_scale, :variant_unit_with_scale, :unit_value,
        :unit_description, :variant_unit_name,
        :display_as, :sku, :group_buy, :group_buy_unit_size,
        :taxon_ids, :primary_taxon_id, :tax_category_id, :supplier_id,
        :meta_keywords, :notes, :inherits_properties, :shipping_category_id,
        { product_properties_attributes: [:id, :property_name, :value],
          variants_attributes: [PermittedAttributes::Variant.attributes],
          image_attributes: [:attachment] }
      ]
    end
  end
end
