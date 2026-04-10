class CreatePresetTags < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_tags do |t|
      t.references :preset, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :preset_tags, [ :preset_id, :tag_id ], unique: true
  end
end
