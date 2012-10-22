require 'opensuse/ldap'

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

    Suse::Ldap.migrate_config_file_to_application_settings!
  end
end
