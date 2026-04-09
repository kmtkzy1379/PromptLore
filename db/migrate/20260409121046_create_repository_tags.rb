class CreateRepositoryTags < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_tags do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :repository_tags, [ :repository_id, :tag_id ], unique: true
  end
end
