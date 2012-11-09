module Opensuse
  module Authentication
    class HttpBasicEngine
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

        user = nil

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

          @user_login = login

          read_only_hosts = Array(configuration['read_only_hosts']) || []
          read_only_hosts << configuration['webui_host'] if configuration['webui_host'] # This was used in config files until OBS 2.1

          if read_only_hosts.include?(environment['REMOTE_HOST']) || read_only_hosts.include?(environment['REMOTE_ADDR'])
            if environment['HTTP_USER_AGENT'] && environment['HTTP_USER_AGENT'].match(/^(obs-webui|obs-software)/)
             user = User.find_by_login("_nobody_")
            end
          else
            logger.send :error, "Anonymous configured, but #{read_only_hosts.inspect} does not include '#{environment['REMOTE_HOST']} '#{environment['REMOTE_ADDR']}'}'"
          end

          user = User.find_with_credentials(login, password)

          if user.nil?
            [nil, "Unknown user '#{login}' or invalid password"]
          else
            user
          end
        else
          logger.send :debug, "No authentication string was sent"
          [nil, "Authentication required"]
        end
      end
    end
  end
end