class ApplicationSettingsController < ApplicationController
  def index
    # Request settings data from API application
    response = ActiveXML::transport.direct_http(URI('/application_settings'))
    xml_application_settings = Nokogiri::XML(response)


    @application_settings = {}
    xml_application_settings.children.children.each do |child|
      unless child.name == 'text'
        Rails.logger.debug "#{ child.name.to_sym } => #{ child.children.to_s }"
        @application_settings[child.name.to_sym] = child.children.to_s
      end
    end
    session[:application_settings] = @application_settings
  end

  def create
    # TODO Post params to API and get response
    @application_settings = {}
    data = "<hash>"
    session[:application_settings].each do |key, value|
      @application_settings[key] = params[key]
      data << "<#{ key }>#{ CGI.escapeHTML(@application_settings[key]) }</#{ key }>"
    end
    data << "</hash>"

    begin
      response = ActiveXML::transport.direct_http(URI('/application_settings/update_application_settings'), :method => 'PUT', :data => data)
      flash[:success] = "Configuration options were successfully saved."
      redirect_to :controller => 'configuration'

    rescue ActiveXML::Transport::Error => e
      xml = Nokogiri::XML.parse(e.to_s)
      flash_errors = xml.children.children.children.children.map { |child| " #{ child.to_s }"}.join
      Rails.logger.debug "\n\n\nErrors=#{ flash_errors }"

      flash[:error] = ("Configuration options were not saved. #{ flash_errors }").html_safe
      render 'application_settings/index'
    end
  end
end