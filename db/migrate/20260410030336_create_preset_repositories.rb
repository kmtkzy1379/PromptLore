class CreatePresetRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_repositories do |t|
      t.references :preset, null: false, foreign_key: true
      t.references :repository, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :preset_repositories, [ :preset_id, :repository_id ], unique: true
  end
end
