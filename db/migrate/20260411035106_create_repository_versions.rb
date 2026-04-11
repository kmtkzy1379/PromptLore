class CreateRepositoryVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_versions do |t|
      t.references :repository, null: false, foreign_key: true
      t.integer    :version_number, null: false
      t.string     :name, null: false
      t.text       :description
      t.string     :memo
      t.boolean    :pinned, default: false, null: false
      t.integer    :file_type, null: false, default: 0
      t.integer    :visibility, null: false, default: 0
      t.json       :tag_names, default: []
      t.json       :category_names, default: []
      t.timestamps
    end
    add_index :repository_versions, [ :repository_id, :version_number ], unique: true
  end
end
