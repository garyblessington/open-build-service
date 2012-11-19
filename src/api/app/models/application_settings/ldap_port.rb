class ApplicationSettings::LdapPort < ApplicationSetting
  validates :integer_value, :presence => true, numericality: { only_integer: true }

  def self.get
    first || create!(:integer_value => 389)
  end

  def value
   integer_value
  end

  def value=(new_value)
    self.integer_value = new_value
  end
end