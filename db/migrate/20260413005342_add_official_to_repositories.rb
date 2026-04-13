class AddOfficialToRepositories < ActiveRecord::Migration[8.1]
  def change
    add_column :repositories, :official, :boolean, default: false, null: false
  end
end
