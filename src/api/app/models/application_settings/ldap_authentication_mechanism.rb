class ApplicationSettings::LdapAuthentication < ApplicationSetting
  validates :string_value, :inclusion => { :in => ['md5', 'cleartext'] }

  def self.get
    first || create!(:string_value => 'md5')
  end

  def value
   string_value
  end

  def value=(new_value)
    self.string_value = new_value
  end
end