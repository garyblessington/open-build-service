require 'ldap'

module Suse
  class Ldap
    # referrals - Set to true for authentication with Windows 2003 AD
    # attempts_count - Max number of times to attempt to contact the LDAP servers
    # port - LDAP port defaults to 636 for ldaps and 389 for ldap and ldap with StartTLS
    # search_base - Override with your company's ldap search base for the users who will use OBS
    # search_attribute - Sam Account Name is the login name for LDAP
    # user_name_attribute - The attribute the users name is stored in
    # search_user - Credentials to use to search ldap for the username
    # search_auth - Credentials to use to search ldap for the username
    # filter_users_by_group_name - By default any LDAP user can be used to authenticate to the OBS. In some deployments this may be too broad - this allows only users in a specific group
      # Note this is joined to the normal selection like so:
      #   (&(#{ search_attr }=#{ login })#{ filter_users_by_group_name })
      # giving an ldap search of:
      #   (&(sAMAccountName=#{login})(memberof=CN=group,OU=Groups,DC=Domain Component))
      # Also note that openLDAP must be configured to use the memberOf overlay

    # How to verify:
    #   :ldap = attempt to bind to ldap as user using supplied credentials
    #   :local = compare the credentials supplied with those in
    #            LDAP using authentication_attribute & authentication_mechanism
    #            authentication_mechanism can be :md5 or :cleartext
    # authenticate
    # authentication_attribute
    # authentication_mechanism

    # ldap_entry_base -
    # sn_attribute_required -
    # entry_base_dn - Base dn for the new added entry
    # sn_attribute_required -Is sn attribute required? It is a necessary attribute for most of people objectclass used for adding new entry

    # group_support - Whether to search group info from ldap
    # group_search_base - Company's ldap search base for groups
    # group_title_attribute - The attribute the group name is stored in

    def self.enabled?
      # This should replace all current application references to -- if defined?( CONFIG['ldap_mode'] ) && CONFIG['ldap_mode'] == :on
      ldap_mode = ApplicationSettings::LdapMode.first
      ldap_mode.nil? ? false : ldap_mode.value
    end

    def authenticate!
      begin
        logger.debug( "Using LDAP to find #{login}" )
        ldap_info = User.find_with_ldap( login, passwd )
      rescue LoadError
        logger.warn "ldap_mode selected but 'ruby-ldap' module not installed."
        ldap_info = nil # now fall through as if we'd not found a user
      rescue Exception
        logger.debug "#{login} not found in LDAP."
        ldap_info = nil # now fall through as if we'd not found a user
      end

      if not ldap_info.nil?
        # We've found an ldap authenticated user - find or create an OBS userDB entry.
        @http_user = User.find_by_login( login )
        if @http_user
          # Check for ldap updates
          if @http_user.email != ldap_info[0]
            @http_user.email = ldap_info[0]
            @http_user.save
          end
        else
          if CONFIG['new_user_registration'] == "deny"
            logger.debug( "No user found in database, creation disabled" )
            render_error( :message => "User '#{login}' does not exist<br>#{errstr}", :status => 401 )
            @http_user=nil
            return false
          end
          logger.debug( "No user found in database, creating" )
          logger.debug( "Email: #{ldap_info[0]}" )
          logger.debug( "Name : #{ldap_info[1]}" )
          # Generate and store a fake pw in the OBS DB that no-one knows
          chars = ["A".."Z","a".."z","0".."9"].collect { |r| r.to_a }.join
          fakepw = (1..24).collect { chars[rand(chars.size)] }.pack("C*")
          newuser = User.create(
            :login => login,
            :password => fakepw,
            :password_confirmation => fakepw,
            :email => ldap_info[0] )
          unless newuser.errors.empty?
            errstr = String.new
            logger.debug("Creating User failed with: ")
            newuser.errors.each_full do |msg|
              errstr = errstr+msg
              logger.debug(msg)
            end
            render_error( :message => "Cannot create ldap userid: '#{login}' on OBS<br>#{errstr}",
              :status => 401 )
            @http_user=nil
            return false
          end
          newuser.realname = ldap_info[1]
          newuser.state = User.states['confirmed']
          newuser.state = User.states['unconfirmed'] if CONFIG['new_user_registration'] == "confirmation"
          newuser.adminnote = "User created via LDAP"
          user_role = Role.find_by_title("User")
          newuser.roles << user_role

          logger.debug( "saving new user..." )
          newuser.save

          @http_user = newuser
        end
      else
        logger.debug( "User not found with LDAP, falling back to database" )
        @http_user = User.find_with_credentials login, passwd
      end
    end

    # Populates db-based config model with LDAP details from config file
    # def self.copy_config_to_data!
    #   ldap_config = LdapConfig.first || LdapConfig.new
    #   ldap_config.attributes = {
    #     :mode => CONFIG['ldap_mode'] == :on,
    #     :referrals => CONFIG['ldap_referrals'] == :on,
    #     :maximum_attempts => CONFIG['ldap_max_attempts'],
    #     :port => CONFIG['ldap_port'],
    #     :search_base => CONFIG['ldap_search_base'],
    #     :search_attribute => CONFIG['ldap_search_attr'],
    #     :user_name_attribute => CONFIG['ldap_name_attr'],
    #     :mail_attribute => CONFIG['ldap_mail_attr'],
    #     :search_user => CONFIG['ldap_search_user'],
    #     :search_auth => CONFIG['ldap_search_auth'],
    #     :filter_users_by_group_name => CONFIG['ldap_user_filter'],
    #     :authentication => CONFIG['ldap_authenticate'],
    #     :authentication_attribute => CONFIG['ldap_auth_attr'],
    #     :authentication_mechanism => CONFIG['ldap_auth_mech'],
    #     :update_support => CONFIG['ldap_update_support'] == :on,
    #     :object_class => CONFIG['ldap_object_class'],
    #     :entry_base_dn => CONFIG['ldap_entry_base'],
    #     :sn_attribute_required => CONFIG['ldap_sn_attr_required'] == :on,
    #     :group_support => CONFIG['ldap_group_support'] == :on,
    #     :group_search_base => CONFIG['ldap_group_search_base'],
    #     :group_title_attribute => CONFIG['ldap_group_title_attr'],
    #     :group_objectclass_attribute => CONFIG['ldap_group_objectclass_attr']
    #   }
    #   ldap_config.save
    # end
  end
end