class ApplicationSettings::LdapUserMemberOfAttribute < ApplicationSetting
  DEFAULT_VALUE = 'memberOf'

  validates :string_value, :presence => true, :allow_nil => true

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