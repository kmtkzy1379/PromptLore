class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :file_type, null: false, default: 0
      t.integer :visibility, null: false, default: 0
      t.integer :downloads_count, null: false, default: 0
      t.integer :likes_count, null: false, default: 0

      t.timestamps
    end

    add_index :repositories, :file_type
    add_index :repositories, :visibility
  end
end
