class ApplicationSettings::LdapMaximumAttempts < ApplicationSetting
  validates :integer_value, :presence => true

  def self.get
    first || create!(:integer_value => 10)
  end

  def value
   integer_value
  end

  def value=(new_value)
    self.integer_value = new_value
  end
end