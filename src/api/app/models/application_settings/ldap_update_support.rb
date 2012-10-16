class ApplicationSettings::LdapUpdateSupport < ApplicationSetting
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