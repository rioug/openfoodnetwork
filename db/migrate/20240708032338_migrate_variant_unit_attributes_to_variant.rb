class MigratVariantUnitAttributesToVariant < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE spree_variants
      SET
        variant_unit = spree_products.variant_unit,
        variant_unit_scale = spree_products.variant_unit_scale,
        variant_unit_name = spree_products.variant_unit_name
      FROM spree_products
      WHERE spree_variants.product_id = spree_products.id
    SQL
    )
  end
end
