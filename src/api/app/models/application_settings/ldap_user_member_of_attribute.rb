class ApplicationSettings::LdapUserMemberOfAttribute < ApplicationSetting
  DEFAULT_VALUE = 'memberOf'

  def self.get
    first || create!(:string_value => DEFAULT_VALUE)
  end

  def value
   string_value
  end

  def value=(new_value)
    self.string_value = new_value || ''
  end
end