# When set to true this will make LDAP server requests that retrieve data on memberOf attributes for the given user.
# If a group has been defined as requiring LDAP permission (ldap_member_of_required => true) and the user does not have a memberOf
# attribute for that group then they will not have access to it.
# Use of this option requires that the following options are set:
#   ldap_mode => true
#   ldap_group_support => true

class ApplicationSettings::LdapGroupMemberOfValidation < ApplicationSetting
  validates :boolean_value, :inclusion => { :in => [true, false] }

  def self.get
    first || create!(:boolean_value => false)
  end

  def value
   boolean_value
  end

  def value=(new_value)
    self.boolean_value = new_value
  end
end