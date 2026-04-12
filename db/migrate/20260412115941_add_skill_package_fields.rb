class AddSkillPackageFields < ActiveRecord::Migration[8.1]
  def change
    add_column :presets, :is_skill_package, :boolean, default: false, null: false
    add_column :preset_items, :subdirectory, :string, default: "", null: false
    add_column :preset_version_items, :subdirectory, :string, default: "", null: false
  end
end
