module Msf
  module RPC
    API_VERSION = '1.0'

    class Exception < RuntimeError
      attr_accessor :message

      def initialize(message)
        self.message = message
      end

      def to_s
        self.message
      end
    end

    class ServerException < RuntimeError
      attr_accessor :code, :message, :error_class, :error_backtrace

      def initialize(code, message, error_class, error_backtrace = [])
        self.code            = code
        self.message         = message
        self.error_class     = error_class
        self.error_backtrace = error_backtrace
      end

      def to_s
        self.message
      end
    end
  end
end
