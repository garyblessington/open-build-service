class ApplicationSettings::LdapUserNameAttribute < ApplicationSetting
  validates :string_value, :presence => true, :allow_nil => true

  def self.get
    first || create!(:string_value => 'cn')
  end

  def value
   string_value
  end

  def value=(new_value)
    self.string_value = new_value || ''
  end
end