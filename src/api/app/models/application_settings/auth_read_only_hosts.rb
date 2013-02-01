class ApplicationSettings::AuthReadOnlyHosts < ApplicationSetting
  def self.get
    first || create!(:string_value => '')
  end

  def value
   string_value
  end

  def value=(new_value)
    if new_value.is_a?(Array)
      self.string_value = new_value.join(',')
    else
      self.string_value = new_value || ''
    end
  end
end