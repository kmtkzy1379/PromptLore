class CreateRepositoryCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :repository_categories do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :repository_categories, [ :repository_id, :category_id ], unique: true
  end
end
