module Opensuse
  module Authentication
    class CredentialsEngine
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