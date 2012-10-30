module Opensuse
  module Authentication
    class CredentialsEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment
      attr_accessor :user_login

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

        logger.send :debug, "AUTH: #{authorization.inspect}"

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

          user_login = login

          user = User.find_with_credentials(login, password)

          if user.nil?
            [nil, "Unknown user '#{login}'' or invalid password"]
          else
            user
          end
        end
      end
    end
  end
end