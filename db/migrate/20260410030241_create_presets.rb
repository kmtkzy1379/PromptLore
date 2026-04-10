class CreatePresets < ActiveRecord::Migration[8.1]
  def change
    create_table :presets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.boolean :official, null: false, default: false
      t.integer :likes_count, null: false, default: 0
      t.integer :downloads_count, null: false, default: 0

      t.timestamps
    end
    add_index :presets, :visibility
    add_index :presets, :official
  end
end
