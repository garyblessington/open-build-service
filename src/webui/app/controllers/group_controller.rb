class GroupController < ApplicationController

  include ApplicationHelper

  def autocomplete
    required_parameters :term
    render :json => Group.list(params[:term])
  end

  def index
    @groups = []
    group_names = Group.list(nil, :login => session[:login])
    group_names.each do |group_name|
      @groups << Group.find_cached(group_name)
    end
  end

  def show
    required_parameters :id

    # TODO Ensure that a person has access to this group, and redirect them if they do not

    @group = Group.find_cached(params[:id])
    unless @group
      flash[:error] = "Group '#{params[:id]}' does not exist"
      redirect_back_or_to :action => 'index' and return
    end
  end

  def edit
    required_parameters :id
    @group = Group.find(params[:id])
    unless @group
      flash[:error] = "Group '#{params[:id]}' does not exist"
      redirect_back_or_to :action => 'index' and return
    end
  end

  def update
    begin
      @group = Group.find(params[:id])

      # Resend all existing users or API will delete them
      group_person_data = "<person>"
      if @group.person.has_elements?
        @group.person.each do |member|
          group_person_data << "<person userid=\"#{ member.userid }\"/>"
        end
      end
      group_person_data << "</person>"

      data = "<group><title>#{ CGI.escapeHTML(params[:title]) }</title><ldap_group_member_of_validation>#{ CGI.escapeHTML(params[:ldap_group_member_of_validation]) }</ldap_group_member_of_validation>#{ group_person_data }</group>"
      ActiveXML::transport.direct_http(URI("/group/#{ @group.value('title') }"), :method => 'PUT', :data => data)

      Group.free_cache(:all)
      @group = Group.find_cached(params[:title])

      flash[:note] = "Group #{ @group.value('title') } was updated successfully."
      redirect_to groups_path

    rescue ActiveXML::Transport::Error => e
      message = ActiveXML::Transport.extract_error_message(e)[0]

      flash[:error] = "Group #{ @group.value('title') } was not updated. " << message
    end
  end
end
