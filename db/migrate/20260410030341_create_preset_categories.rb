class CreatePresetCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_categories do |t|
      t.references :preset, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :preset_categories, [ :preset_id, :category_id ], unique: true
  end
end
