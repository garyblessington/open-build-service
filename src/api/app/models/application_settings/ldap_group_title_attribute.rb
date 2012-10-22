class ApplicationSettings::LdapGroupTitleAttribute < ApplicationSetting
  validates :string_value, :presence => true

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