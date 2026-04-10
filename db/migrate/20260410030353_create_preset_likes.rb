class CreatePresetLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :preset, null: false, foreign_key: true

      t.timestamps
    end
    add_index :preset_likes, [ :user_id, :preset_id ], unique: true
  end
end
