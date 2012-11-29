require 'ldap'

module Suse
  class Ldap
    # Notes from config file options...
    # search_base - LDAP search base for the users who will use OBS
    # user_name_attribute - The attribute the users name is stored in
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





    def self.servers
      # Colon-separated list of LDAP servers, one of which is selected randomly during a connection
      ApplicationSettings::LdapServers.get.value
    end

    def self.port
      # LDAP port defaults to 636 for ldaps and 389 for ldap and ldap with StartTLS
      if ssl?
        ApplicationSettings::LdapPort.get.value || 636
      else
        ApplicationSettings::LdapPort.get.value || 389
      end
    end

    def self.maximum_attempts
      # Number of attempts at making a connection to an LDAP server
      ApplicationSettings::LdapMaximumAttempts.get.value
    end

    def self.ssl?
      # Use SSL or not?
      ApplicationSettings::LdapSsl.get.value
    end

    def self.start_tls?
      # Use StartTLS or not?
      ApplicationSettings::LdapStartTls.get.value
    end

    def self.referrals?
      # Enabled for authentication with Windows 2003 AD
      ApplicationSettings::LdapReferrals.get.value
    end

    def self.enabled?
      # LDAP mode enabled? All other LDAP options rely upon this.
      ApplicationSettings::LdapMode.get.value
    end

    def self.entry_base
      # Base dn for the new added entry
      ApplicationSettings::LdapEntryBaseDn.get.value
    end

    def self.user_search_base
      # LDAP search base for the users who will use OBS
      ApplicationSettings::LdapUserSearchBase.get.value
    end

    def self.search_user
      # Credentials to use to search LDAP for the username
      ApplicationSettings::LdapSearchUser.get.value
    end

    def self.search_auth
      # Credentials to use to search LDAP for the username
      ApplicationSettings::LdapSearchAuth.get.value
    end

    def self.search_attribute
      # Sam Account Name is the login name for LDAP
      ApplicationSettings::LdapSearchAttribute.get.value
    end

    def self.user_member_of_attribute
      # The attribute the user memberOf is stored in on the LDAP server
      ApplicationSettings::LdapUserMemberOfAttribute.get.value
    end

    def self.group_object_class_attribute
      # The value of the group objectclass attribute, leave it as "" if objectclass attr doesn't exist
      ApplicationSettings::LdapGroupObjectClassAttribute.get.value
    end

    def self.group_title_attribute
      # The attribute the group name is stored in
      ApplicationSettings::LdapGroupTitleAttribute.get.value
    end

    def self.group_search_base
      # LDAP search base for the groups in this OBS
      ApplicationSettings::LdapGroupSearchBase.get.value
    end

    def self.group_member_of_validation?
      # If enabled, a user can only access groups that they are a memberOf on the LDAP server
      ApplicationSettings::LdapGroupMemberOfValidation.get.value
    end

    def self.group_member_attribute
      # Perform the group_user search with the member attribute of group entry or memberof attribute of user entry
      # It depends on your ldap define
      # The attribute the group member is stored in
      ApplicationSettings::LdapGroupMemberAttribute.get.value
    end

    def self.group_support?
      # Whether to search group info from ldap
      ApplicationSettings::LdapGroupSupport.get.value
    end

    def self.filter_users_by_group_name?
      # By default any LDAP user can be used to authenticate to the OBS.
      # In some deployments this may be too broad - this allows only users in a specific group
      ApplicationSettings::LdapFilterUsersByGroupName.get.value
    end

    def self.mail_attribute
      ApplicationSettings::LdapMailAttribute.get.value
    end

    def self.authentication
      ApplicationSettings::LdapAuthentication.get.value
    end

    def self.authentication_attribute
      ApplicationSettings::LdapAuthenticationAttribute.get.value
    end

    def self.name_attribute
      ApplicationSettings::LdapNameAttribute.get.value
    end

    def self.authentication_mechanism
      ApplicationSettings::LdapAuthenticationMechanism.get.value
    end

    def self.object_class_attribute
      ApplicationSettings::LdapObjectClassAttribute.get.value
    end

    def self.user_name_attribute
      ApplicationSettings::LdapUserNameAttribute.get.value
    end

    def self.sn_attribute_required?
      # Is sn attribute required? It is a necessary attribute for most of people objectclass used for adding new entry
      ApplicationSettings::LdapSnAttributeRequired.get.value
    end


    # Populates db-based config model with LDAP details from config file
    def self.migrate_config_file_to_application_settings!
      ApplicationSettings::LdapServers.init(CONFIG['ldap_servers'] == :on)
      ApplicationSettings::LdapPort.init(CONFIG['ldap_port'] || 389)
      ApplicationSettings::LdapMaximumAttempts.init(CONFIG['ldap_max_attempts'])
      ApplicationSettings::LdapSsl.init(CONFIG['ldap_ssl'] == :on)
      ApplicationSettings::LdapStartTls.init(CONFIG['ldap_start_tls'] == :on)
      ApplicationSettings::LdapReferrals.init(CONFIG['ldap_referrals'] == :on)
      ApplicationSettings::LdapMode.init(CONFIG['ldap_mode'] == :on)
      ApplicationSettings::LdapEntryBaseDn.init(CONFIG['ldap_entry_base'])
      ApplicationSettings::LdapUserSearchBase.init(CONFIG['ldap_search_base'])
      ApplicationSettings::LdapSearchUser.init(CONFIG['ldap_search_user'])
      ApplicationSettings::LdapSearchAuth.init(CONFIG['ldap_search_auth'])
      ApplicationSettings::LdapSearchAttribute.init(CONFIG['ldap_search_attr'])
      ApplicationSettings::LdapUserMemberOfAttribute.init(CONFIG['ldap_user_memberof_attr'])
      ApplicationSettings::LdapGroupObjectClassAttribute.init(CONFIG['ldap_group_objectclass_attr'])
      ApplicationSettings::LdapGroupTitleAttribute.init(CONFIG['ldap_group_title_attr'])
      ApplicationSettings::LdapGroupSearchBase.init(CONFIG['ldap_group_search_base'])
      ApplicationSettings::LdapGroupMemberAttribute.init(CONFIG['ldap_group_member_attr'])
      ApplicationSettings::LdapFilterUsersByGroupName.init(CONFIG['ldap_user_filter'])
      ApplicationSettings::LdapGroupSupport.init(CONFIG['ldap_group_support'] == :on)
      ApplicationSettings::LdapAuthentication.init(CONFIG['ldap_authenticate'] == :on)
      ApplicationSettings::LdapAuthenticationAttribute.init(CONFIG['ldap_auth_attr'])
      ApplicationSettings::LdapAuthenticationMechanism.init(CONFIG['ldap_auth_mech'])
      ApplicationSettings::LdapMailAttribute.init(CONFIG['ldap_mail_attr'])
      ApplicationSettings::LdapObjectClass.init(CONFIG['ldap_object_class'])
      ApplicationSettings::LdapSnAttributeRequired.init(CONFIG['ldap_sn_attr_required'] == :on)
      ApplicationSettings::LdapUpdateSupport.init(CONFIG['ldap_update_support'] == :on)
      ApplicationSettings::LdapUserNameAttribute.init(CONFIG['ldap_name_attr'])
    end
  end
end