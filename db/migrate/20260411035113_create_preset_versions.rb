class CreatePresetVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_versions do |t|
      t.references :preset, null: false, foreign_key: true
      t.integer    :version_number, null: false
      t.string     :name, null: false
      t.text       :description
      t.string     :memo
      t.boolean    :pinned, default: false, null: false
      t.integer    :visibility, null: false, default: 0
      t.boolean    :official, default: false, null: false
      t.json       :tag_names, default: []
      t.json       :category_names, default: []
      t.json       :repository_refs, default: []
      t.timestamps
    end
    add_index :preset_versions, [ :preset_id, :version_number ], unique: true
  end
end
