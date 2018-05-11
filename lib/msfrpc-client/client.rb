# -*- coding: binary -*-

require 'net/http'
require 'openssl'

# MessagePack for data encoding (http://www.msgpack.org/)
require 'msgpack'

# Standardize option parsing
require 'optparse'

# Parse configuration file
require 'yaml'

# Constants used by this client
require 'msfrpc-client/constants'

module Msf
  module RPC
    class Client
      # @!attribute token
      #   @return [String] A login token.
      attr_accessor :token

      # @!attribute info
      #   @return [Hash] Login information.
      attr_accessor :info

      # Initializes the RPC client to connect to: https://127.0.0.1:3790 (TLS1)
      # The connection information is overridden through the optional info hash.
      #
      # @param [Hash] info Information needed for the initialization.
      # @option info [String] :token A token used by the client.
      # @return [void]

      def initialize(info = {})
        @user = nil
        @pass = nil

        self.info = {
          host:  '127.0.0.1',
          port:  3790,
          uri:   '/api/',
          ssl:   true,
          ssl_version: 'TLS1.2',
        }.merge(info)

        self.token = self.info[:token]
      end

      # Logs in by calling the 'auth.login' API. The authentication token will
      # expire after 5 minutes, but will automatically be rewnewed when you
      # make a new RPC request.
      #
      # @param [String] user Username.
      # @param [String] pass Password.
      # @raise RuntimeError Indicating a failed authentication.
      # @return [TrueClass] Indicating a successful login.

      def login(user, pass)
        @user = user
        @pass = pass
        res = self.call('auth.login', user, pass)
        unless res && res['result'] == 'success'
          raise Msf::RPC::Exception.new('Authentication failed')
        end
        self.token = res['token']
        true
      end


      # Attempts to login again with the last known user name and password.
      #
      # @return [TrueClass] Indicating a successful login.

      def re_login
        login(@user, @pass)
      end


      # Calls an API.
      #
      # @param [String] meth The RPC API to call.
      # @param [Array<string>] args The arguments to pass.
      # @raise [RuntimeError] Something is wrong while calling the remote API,
      #                       including:
      #                       * A missing token (your client needs to
      #                         authenticate).
      #                       * A unexpected response from the server, such as
      #                         a timeout or unexpected HTTP code.
      # @raise [Msf::RPC::ServerException] The RPC service returns an error.
      # @return [Hash] The API response. It contains the following keys:
      #  * 'version' [String] Framework version.
      #  * 'ruby' [String] Ruby version.
      #  * 'api' [String] API version.
      # @example
      #  # This will return something like this:
      #  # {"version"=>"4.11.0-dev",
      #  #  "ruby"=>"2.1.5 x86_64-darwin14.0 2014-11-13", "api"=>"1.0"}
      #  rpc.call('core.version')

      def call(meth, *args)
        if meth == 'auth.logout'
          do_logout_cleanup
        end

        unless meth == 'auth.login'
          unless self.token
            raise Msf::RPC::Exception.new('Client not authenticated')
          end
          args.unshift(self.token)
        end

        args.unshift(meth)

        begin
          send_rpc_request(args)
        rescue Msf::RPC::ServerException => e
          if e.message =~ /Invalid Authentication Token/i &&
             meth != 'auth.login' && @user && @pass
            re_login
            args[1] = self.token
            retry
          else
            raise e
          end
        end
      end

      # Closes the client.
      #
      # @return [void]
      def close
        @cli = nil
      end

      #
      # Class methods
      #

      #
      # Provides a parser object that understands the
      # RPC specific options
      #
      def self.option_parser(options)
        parser = OptionParser.new

        parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        parser.separator('')
        parser.separator('RPC Options:')

        parser.on('--rpc-host HOST') do |v|
          options[:host] = v
        end

        parser.on('--rpc-port PORT') do |v|
          options[:port] = v.to_i
        end

        parser.on('--rpc-ssl <true|false>') do |v|
          options[:ssl] = v
        end

        parser.on('--rpc-uri URI') do |v|
          options[:uri] = v
        end

        parser.on('--rpc-user USERNAME') do |v|
          options[:user] = v
        end

        parser.on('--rpc-pass PASSWORD') do |v|
          options[:pass] = v
        end

        parser.on('--rpc-token TOKEN') do |v|
          options[:token] = v
        end

        parser.on('--rpc-config CONFIG-FILE') do |v|
          options[:config] = v
        end

        parser.on('--rpc-help') do
          $stderr.puts parser
          exit(1)
        end

        parser.separator('')

        parser
      end

      #
      # Load options from the command-line, environment.
      # and any configuration files specified
      #
      def self.option_handler(options = {})
        options[:host]   ||= ENV['MSFRPC_HOST']
        options[:port]   ||= ENV['MSFRPC_PORT']
        options[:uri]    ||= ENV['MSFRPC_URI']
        options[:user]   ||= ENV['MSFRPC_USER']
        options[:pass]   ||= ENV['MSFRPC_PASS']
        options[:ssl]    ||= ENV['MSFRPC_SSL']
        options[:token]  ||= ENV['MSFRPC_TOKEN']
        options[:config] ||= ENV['MSFRPC_CONFIG']

        empty_keys = options.keys.select { |k| options[k].nil? }
        empty_keys.each { |k| options.delete(k) }

        config_file = options.delete(:config)

        if config_file
          yaml_data = ::File.read(config_file) rescue nil
          if yaml_data
            yaml = ::YAML.load(yaml_data) rescue nil
            if yaml && yaml.is_a?(::Hash) && yaml['options']
              yaml['options'].each_pair do |k, v|
                case k
                when 'ssl'
                  options[k.intern] = !!(v.to_s =~ /^(t|y|1)/i)
                when 'port'
                  options[k.intern] = v.to_i
                else
                  options[k.intern] = v
                end
              end
            else
              $stderr.puts "Could not parse configuration file: #{config_file}"
              exit(1)
            end
          else
            $stderr.puts "Could not read configuration file: #{config_file}"
            exit(1)
          end
        end

        options[:port] = options[:port].to_i if options[:port]

        options[:ssl] = !!(options[:ssl].to_s =~ /^(t|y|1)/i) if options[:ssl]

        options
      end

      private

      def send_rpc_request(args)
        unless @cli
          @cli = Net::HTTP.new(info[:host], info[:port])
          @cli.use_ssl = info[:ssl]
          @cli.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        req = Net::HTTP::Post.new(self.info[:uri], initheader = {
          'User-Agent' => "Metasploit RPC Client/#{API_VERSION}",
          'Content-Type' => 'binary/message-pack'
          }
        )
        req.body = args.to_msgpack

        begin
          res = @cli.request(req)
        rescue => e
            raise Msf::RPC::ServerException.new(000, e.message, e.class)
        end

        if res && [200, 401, 403, 500].include?(res.code.to_i)
          resp = MessagePack.unpack(res.body)

          # Boolean true versus truthy check required here;
          # RPC responses such as { "error" => "Here I am" } and
          # { "error" => # "" } must be accommodated.
          if resp && resp.is_a?(::Hash) && resp['error'] == true
            raise Msf::RPC::ServerException.new(
              resp['error_code'] || res.code,
              resp['error_message'] || resp['error_string'],
              resp['error_class'], resp['error_backtrace']
            )
          end

          return resp
        else
          if res
            raise Msf::RPC::Exception.new(res.inspect)
          else
            raise Msf::RPC::Exception.new('Unknown error parsing or sending response')
          end
        end
      end

      def do_logout_cleanup
        @user = nil
        @pass = nil
      end
    end
  end
end
