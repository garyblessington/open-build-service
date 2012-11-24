require 'ldap'

module Suse
  class Ldap
    # Notes from config file options...
    # referrals - Set to true for authentication with Windows 2003 AD
    # attempts_count - Max number of times to attempt to contact the LDAP servers
    # port - LDAP port defaults to 636 for ldaps and 389 for ldap and ldap with StartTLS
    # search_base - LDAP search base for the users who will use OBS
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

    def self.servers
      # Colon-separated list of LDAP servers, one of which is selected randomly during a connection
      ApplicationSettings::LdapServers.get.value
    end

    def self.maximum_attempts
      # Number of attempts at making a connection to an LDAP server
      ApplicationSettings::LdapMaximumAttempts.get.value
    end

    def self.ssl?
      ApplicationSettings::LdapSsl.get.value
    end

    def self.port
      if ssl?
        ApplicationSettings::LdapPort.get.value || 636
      else
        ApplicationSettings::LdapPort.get.value || 389
      end
    end

    def self.start_tls?
      ApplicationSettings::LdapStartTls.get.value
    end

    def self.referrals?
      ApplicationSettings::LdapReferrals.get.value
    end

    def self.enabled?
      # TODO This should replace all current application references to -- if defined?( CONFIG['ldap_mode'] ) && CONFIG['ldap_mode'] == :on
      # e.g. Suse::Ldap.enabled?
      # LDAP mode enabled? All other LDAP options rely upon this.
      ApplicationSettings::LdapMode.get.value
    end

    def self.search_base
      # LDAP search base for the users who will use OBS
      ApplicationSettings::LdapSearchBase.get.value
    end

    def self.search_user
      # Credentials to use to search LDAP for the username
      ApplicationSettings::LdapSearchUser.get.value
    end

    def self.search_auth
      # Credentials to use to search LDAP for the username
      ApplicationSettings::LdapSearchAuth.get.value
    end

    def self.member_of_attribute
      # The attribute the user memberOf is stored in on the LDAP server
      ApplicationSettings::LdapMemberOfAttribute.get.value
    end

    def self.group_member_of_validation?
      # If enabled, a user can only access groups that they are a memberOf on the LDAP server
      ApplicationSettings::LdapGroupMemberOfValidation.get.value
    end

    # Populates db-based config model with LDAP details from config file
    def self.migrate_config_file_to_application_settings!
      ApplicationSettings::LdapServers.init(CONFIG['ldap_servers'] == :on)
      ApplicationSettings::LdapMode.init(CONFIG['ldap_mode'] == :on)
      ApplicationSettings::LdapReferrals.init(CONFIG['ldap_referrals'] == :on)
      ApplicationSettings::LdapMaximumAttempts.init(CONFIG['ldap_max_attempts'])
      ApplicationSettings::LdapPort.init(CONFIG['ldap_port'] || 389)
      ApplicationSettings::LdapSearchBase.init(CONFIG['ldap_search_base'])
      ApplicationSettings::LdapSearchAttribute.init(CONFIG['ldap_search_attr'])
      ApplicationSettings::LdapMemberOfAttribute.init(CONFIG['ldap_user_memberof_attr'])
      ApplicationSettings::LdapUserNameAttribute.init(CONFIG['ldap_name_attr'])
      ApplicationSettings::LdapMailAttribute.init(CONFIG['ldap_mail_attr'])
      ApplicationSettings::LdapSearchUser.init(CONFIG['ldap_search_user'])
      ApplicationSettings::LdapSearchAuth.init(CONFIG['ldap_search_auth'])
      ApplicationSettings::LdapFilterUsersByGroupName.init(CONFIG['ldap_user_filter'])
      ApplicationSettings::LdapAuthentication.init(CONFIG['ldap_authenticate'] == :on)
      ApplicationSettings::LdapAuthenticationAttribute.init(CONFIG['ldap_auth_attr'])
      ApplicationSettings::LdapAuthenticationMechanism.init(CONFIG['ldap_auth_mech'])
      ApplicationSettings::LdapUpdateSupport.init(CONFIG['ldap_update_support'] == :on)
      ApplicationSettings::LdapObjectClass.init(CONFIG['ldap_object_class'])
      ApplicationSettings::LdapEntryBaseDn.init(CONFIG['ldap_entry_base'])
      ApplicationSettings::LdapSnAttributeRequired.init(CONFIG['ldap_sn_attr_required'] == :on)
      ApplicationSettings::LdapGroupSupport.init(CONFIG['ldap_group_support'] == :on)
      ApplicationSettings::LdapGroupSearchBase.init(CONFIG['ldap_group_search_base'])
      ApplicationSettings::LdapGroupTitleAttribute.init(CONFIG['ldap_group_title_attr'])
      ApplicationSettings::LdapGroupObjectClassAttribute.init(CONFIG['ldap_group_objectclass_attr'])
    end
  end
end