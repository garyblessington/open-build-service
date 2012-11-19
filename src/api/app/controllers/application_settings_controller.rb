class ApplicationSettingsController < ApplicationController
  def index
    Rails.logger.debug "ApplicationSetting.to_xml = #{ ApplicationSetting.to_xml }"
    render :text => ApplicationSetting.to_xml, :content_type => "text/xml"
  end

  def update_application_settings
    xml = Xmlhash.parse(request.raw_post)
    Rails.logger.debug "Updating application settings #{ xml.inspect }"

    errors = []
    xml.keys.each do |key|
      begin
        Rails.logger.debug "Updating #{ key } with #{ xml[key] }"
        application_setting = eval("ApplicationSettings::#{ key }.get")
        application_setting.value = xml[key]
        unless application_setting.save
          Rails.logger.debug "Error: #{ application_setting.errors.full_messages } #{ application_setting.inspect }"
          errors << application_setting.errors.full_messages.map { |message| "#{ key }#{ message.gsub('Integer', '').gsub('Boolean', '').gsub('String', '') }" }
        end
      rescue
        Rails.logger.debug "Error: #{ application_setting.errors.full_messages } #{ application_setting.inspect }"
        errors << application_setting.errors.full_messages
      end
    end

    respond_to do |format|
      if errors.empty?
        format.xml  { head :ok }
      else
        format.xml  { render :xml => errors, :status => :unprocessable_entity }
      end
    end
  end
end