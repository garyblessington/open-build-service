#http://pivotallabs.com/users/jdean/blog/articles/1708-creating-strongly-typed-app-wide-user-editable-settings
# To create a new configuration option:
# 1. Create a new model ApplicationSettings::OptionName and define its type in there
# 2. Add the parameter to the to_xml option so that clients can request it

require "builder"

class ApplicationSetting < ActiveRecord::Base
  attr_accessible :string_value, :integer_value, :boolean_value
  def self.init(new_value)
    application_setting = self.get
    application_setting.value = new_value
    application_setting.save
    application_setting.value
  end

  def self.to_xml
    # For now, this has to be handled manually. There is no easy way to get all the subclasses of ApplicationSetting and their values
    # due to how Ruby lazy loads classes.
    application_settings = {
      :LdapServers => ApplicationSettings::LdapServers.get.value,
      :LdapPort => ApplicationSettings::LdapPort.get.value,
      :LdapMaximumAttempts => ApplicationSettings::LdapMaximumAttempts.get.value,
      :LdapSsl => ApplicationSettings::LdapSsl.get.value,
      :LdapStartTls => ApplicationSettings::LdapStartTls.get.value,
      :LdapReferrals => ApplicationSettings::LdapReferrals.get.value,
      :LdapMode => ApplicationSettings::LdapMode.get.value,
      :LdapEntryBaseDn => ApplicationSettings::LdapEntryBaseDn.get.value,
      :LdapUserSearchBase => ApplicationSettings::LdapUserSearchBase.get.value,
      :LdapSearchUser => ApplicationSettings::LdapSearchUser.get.value,
      :LdapSearchAuth => ApplicationSettings::LdapSearchAuth.get.value,
      :LdapSearchAttribute => ApplicationSettings::LdapSearchAttribute.get.value,
      :LdapUserMemberOfAttribute => ApplicationSettings::LdapUserMemberOfAttribute.get.value,
      :LdapGroupObjectClassAttribute => ApplicationSettings::LdapGroupObjectClassAttribute.get.value,
      :LdapGroupTitleAttribute => ApplicationSettings::LdapGroupTitleAttribute.get.value,
      :LdapGroupSearchBase => ApplicationSettings::LdapGroupSearchBase.get.value,
      :LdapGroupMemberOfValidation => ApplicationSettings::LdapGroupMemberOfValidation.get.value,
      :LdapGroupMemberAttribute => ApplicationSettings::LdapGroupMemberAttribute.get.value,
      :LdapFilterUsersByGroupName => ApplicationSettings::LdapFilterUsersByGroupName.get.value,
      :LdapGroupSupport => ApplicationSettings::LdapGroupSupport.get.value,
      :LdapAuthentication => ApplicationSettings::LdapAuthentication.get.value,
      :LdapAuthenticationAttribute => ApplicationSettings::LdapAuthenticationAttribute.get.value,
      :LdapAuthenticationMechanism => ApplicationSettings::LdapAuthenticationMechanism.get.value,
      :LdapMailAttribute => ApplicationSettings::LdapMailAttribute.get.value,
      :LdapObjectClass => ApplicationSettings::LdapObjectClass.get.value,
      :LdapSnAttributeRequired => ApplicationSettings::LdapSnAttributeRequired.get.value,
      :LdapUpdateSupport => ApplicationSettings::LdapUpdateSupport.get.value,
      :LdapUserNameAttribute => ApplicationSettings::LdapUserNameAttribute.get.value,
      }
    application_settings.to_xml
  end
end
