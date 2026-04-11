class CreatePresetVersionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_version_items do |t|
      t.references :preset_version, null: false, foreign_key: true
      t.integer    :file_type, null: false, default: 0
      t.integer    :position, null: false, default: 0
      t.timestamps
    end
  end
end
