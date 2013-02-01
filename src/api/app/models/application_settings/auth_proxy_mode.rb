class ApplicationSettings::AuthProxyMode < ApplicationSetting
  validates :string_value, :inclusion => { :in => %w[on off simulate] }, :allow_blank => true

  def self.get
    first || create!(:string_value => '')
  end

  def value
   string_value
  end

  def value=(new_value)
    self.string_value = new_value || ''
  end
end