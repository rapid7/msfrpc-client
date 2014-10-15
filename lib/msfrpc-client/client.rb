# MessagePack for data encoding (http://www.msgpack.org/)
require 'msgpack'

# Standardize option parsing
require "optparse"

# Parse configuration file
require 'yaml'

# Rex library from the Metasploit Framework
require 'rex'
require 'rex/proto/http'

# Constants used by this client
require 'msfrpc-client/constants'

module Msf
module RPC

class Client

	attr_accessor :token, :info

	#
	# Create a new RPC Client instance
	#
	def initialize(config={})

		self.info = {
			:host => '127.0.0.1',
			:port => 3790,
			:uri  => '/api/' + Msf::RPC::API_VERSION,
			:ssl  => true,
			:ssl_version => 'TLS1',
			:context     => {}
		}.merge(config)

		# Set the token
		self.token = self.info[:token]

		if not self.token and (info[:user] and info[:pass])
			login(info[:user], info[:pass])
		end
	end

	#
	# Authenticate using a username and password
	#
	def login(user,pass)
		res = self.call("auth.login", user, pass)
		if(not (res and res['result'] == "success"))
			raise RuntimeError, "authentication failed"
		end
		self.token = res['token']
		true
	end

	#
	# Prepend the authentication token as the first parameter
	# of every call except auth.login. This simplifies the
	# calling API.
	#
	def call(meth, *args)
		if(meth != "auth.login")
			if(not self.token)
				raise RuntimeError, "client not authenticated"
			end
			args.unshift(self.token)
		end

		args.unshift(meth)

		if not @cli
			@cli = Rex::Proto::Http::Client.new(info[:host], info[:port], info[:context], info[:ssl], info[:ssl_version])
			@cli.set_config(
				:vhost => info[:host],
				:agent => "Metasploit Pro RPC Client/#{API_VERSION}",
				:read_max_data => (1024*1024*512)
			)
		end

		req = @cli.request_cgi(
			'method' => 'POST',
			'uri'    => self.info[:uri],
			'ctype'  => 'binary/message-pack',
			'data'   => args.to_msgpack
		)

		res = @cli.send_recv(req)

		if res and [200, 401, 403, 500].include?(res.code)
			resp = MessagePack.unpack(res.body)

			if resp and resp.kind_of?(::Hash) and resp['error'] == true
				raise Msf::RPC::ServerException.new(res.code, resp['error_message'] || resp['error_string'], resp['error_class'], resp['error_backtrace'])
			end

			return resp
		else
			raise RuntimeError, res.inspect
		end
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

		parser.banner = "Usage: #{$0} [options]"
		parser.separator('')
		parser.separator('RPC Options:')

		parser.on("--rpc-host HOST") do |v|
			options[:host] = v
		end

		parser.on("--rpc-port PORT") do |v|
			options[:port] = v.to_i
		end

		parser.on("--rpc-ssl <true|false>") do |v|
			options[:ssl] = v
		end

		parser.on("--rpc-uri URI") do |v|
			options[:uri] = v
		end

		parser.on("--rpc-user USERNAME") do |v|
			options[:user] = v
		end

		parser.on("--rpc-pass PASSWORD") do |v|
			options[:pass] = v
		end

		parser.on("--rpc-token TOKEN") do |v|
			options[:token] = v
		end

		parser.on("--rpc-config CONFIG-FILE") do |v|
			options[:config] = v
		end

		parser.on("--rpc-help") do
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
	def self.option_handler(options={})
		options[:host]   ||= ENV['MSFRPC_HOST']
		options[:port]   ||= ENV['MSFRPC_PORT']
		options[:uri]    ||= ENV['MSFRPC_URI']
		options[:user]   ||= ENV['MSFRPC_USER']
		options[:pass]   ||= ENV['MSFRPC_PASS']
		options[:ssl]    ||= ENV['MSFRPC_SSL']
		options[:token]  ||= ENV['MSFRPC_TOKEN']
		options[:config] ||= ENV['MSFRPC_CONFIG']

		empty_keys = options.keys.select{|k| options[k].nil? }
		empty_keys.each { |k| options.delete(k) }

		config_file = options.delete(:config)

		if config_file
			yaml_data = ::File.read(config_file) rescue nil
			if yaml_data
				yaml = ::YAML.load(yaml_data) rescue nil
				if yaml and yaml.kind_of?(::Hash) and yaml['options']
					yaml['options'].each_pair do |k,v|
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
					$stderr.puts "[-] Could not parse configuration file: #{config_file}"
					exit(1)
				end
			else
				$stderr.puts "[-] Could not read configuration file: #{config_file}"
				exit(1)
			end
		end

		if options[:port]
			options[:port] = options[:port].to_i
		end

		if options[:ssl]
			options[:ssl] = !!(options[:ssl].to_s =~ /^(t|y|1)/i)
		end

		options
	end

end
end
end

