module Opensuse
  module Authentication
    class AnonymousEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        user = nil

        read_only_hosts = Array(configuration['read_only_hosts']) || []
        read_only_hosts << configuration['webui_host'] if configuration['webui_host'] # This was used in config files until OBS 2.1
        return_message = ""

        if read_only_hosts.include?(environment['REMOTE_HOST']) || read_only_hosts.include?(environment['REMOTE_ADDR'])
          if environment['HTTP_USER_AGENT'] && environment['HTTP_USER_AGENT'].match(/^(obs-webui|obs-software)/)
            user = User.find_by_login('_nobody_')
          else
            logger.send :debug, "No authentication string was sent"
            return_message = "Authentication required"
          end
        else
          return_message = "Anonymous configured, but #{read_only_hosts.join(', ')} does not include '#{environment['REMOTE_HOST']} '#{environment['REMOTE_ADDR']}'}'"
          logger.send :error, error_message
        end

        if user.nil?
          [nil, return_message]
        else
          user
        end
      end
    end
  end
end