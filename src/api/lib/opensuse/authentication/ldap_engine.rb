module Opensuse
  module Authentication
    class LdapEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        if environment.has_key? 'X-HTTP_AUTHORIZATION'
          # try to get it where mod_rewrite might have put it
          authorization = environment['X-HTTP_AUTHORIZATION'].to_s.split
        elsif environment.has_key? 'Authorization'
          # for Apace/mod_fastcgi with -pass-header Authorization
          authorization = environment['Authorization'].to_s.split
        elsif environment.has_key? 'HTTP_AUTHORIZATION'
          # this is the regular location
          authorization = environment['HTTP_AUTHORIZATION'].to_s.split
        end

        logger.debug "AUTH: #{authorization.inspect}"

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

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


