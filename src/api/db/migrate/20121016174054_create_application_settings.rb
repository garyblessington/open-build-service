class CreateApplicationSettings < ActiveRecord::Migration
  def change
    create_table :application_settings do |t|
      t.string :type, :null => false
      t.string :string_value
      t.integer :integer_value
      t.boolean :boolean_value
      t.timestamps
    end

    add_index :application_settings, :type, :unique => true
  end
end
