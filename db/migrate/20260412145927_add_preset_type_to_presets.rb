class AddPresetTypeToPresets < ActiveRecord::Migration[8.1]
  def change
    add_column :presets, :preset_type, :integer, default: 0, null: false
  end
end
