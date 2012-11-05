module Opensuse
  module Authentication
    class LdapEngine
      include Opensuse::Authentication::Logger
      include Opensuse::Authentication::HttpHeader

      attr_reader :configuration, :environment
      attr_accessor :user_login, :ldap_user_info

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        authorization = extract_authorization_from_header

        logger.send :debug, "AUTH: #{authorization.inspect}"

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

          user_login = login

          # Set password to the empty string in case no password is transmitted in the auth string
          password ||= ""

          # Disallow empty passwords to prevent LDAP lockouts
          return [nil, "User '#{login} did not provide a password'"] if !password || password == ""

          user = nil
          ldap_info = nil

          begin
            #logger.debug( "Using LDAP to find #{login}" )
            ldap_info, ldap_user_info = User.find_with_ldap(login, passwd)
          rescue LoadError
            loggersend :warn, "ldap_mode selected but 'ruby-ldap' module not installed."
          rescue Exception
            logger.send :debug, "#{login} not found in LDAP."
          end

          if ldap_info
            # We've found an LDAP authenticated user - find or create an OBS user database entry
            user = User.find_by_login(login)
            user.update_attributes(:email => ldap_info[0]) if user
          end

          if user
            user
          else
            [nil, "Unknown user '#{login}' or invalid password"]
          end
        end
      end
    end
  end
end


