module Opensuse
  module Authentication
    module Logger
      def logger
        if defined?(Rails)
          Rails.logger
        else
          logger = Logger.new(STDOUT)
          logger.progname = "self.class.to_s"
          return logger
        end
      end
    end
  end
end