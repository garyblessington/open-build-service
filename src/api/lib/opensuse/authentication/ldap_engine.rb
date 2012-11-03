module Opensuse
  module Authentication
    class LdapEngine
      include Opensuse::Authentication::Logger
      include Opensuse::Authentication::HttpHeader

      attr_reader :configuration, :environment
      attr_accessor :user_login

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

          user = Suse::Ldap.authenticate!(login, password)

          if user.nil?
            user
          else
            [nil, "Unknown user '#{login}' or invalid password"]
          end
        end
      end
    end
  end
end


