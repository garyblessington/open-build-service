class ApplicationSettings::LdapGroupMemberAttribute < ApplicationSetting

  def self.get
    first || create!(:string_value => 'member')
  end

  def value
   string_value
  end

  def value=(new_value)
    self.string_value = new_value || ''
  end
end