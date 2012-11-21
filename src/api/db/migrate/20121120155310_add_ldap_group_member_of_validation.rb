class AddLdapGroupMemberOfValidation < ActiveRecord::Migration
  def up
    add_column :groups, :ldap_group_member_of_validation, :boolean
    add_index :groups, :ldap_group_member_of_validation
  end

  def down
    remove_column :groups, :ldap_group_member_of_validation, :boolean
  end
end
