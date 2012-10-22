class ApplicationSetting < ActiveRecord::Base
  attr_accessible :string_value, :integer_value, :boolean_value
  def self.init(new_value)
    application_setting = self.get
    application_setting.value = new_value
    application_setting.save
    application_setting.value
  end
end
