#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'msfrpc-client'
require 'rex/ui'


# Use the RPC option parser to handle standard flags
opts   = {}
parser = Msf::RPC::Client.option_parser(opts)
parser.parse!(ARGV)

# Parse additional options, environment variables, etc
opts = Msf::RPC::Client.option_handler(opts)

# Create the RPC client with our parsed options
rpc  = Msf::RPC::Client.new(opts)

$stdout.puts "[*] The RPC client is available in variable 'rpc'"
if rpc.token
	$stdout.puts "[*] Sucessfully authenticated to the server"
end

$stdout.puts "[*] Starting IRB shell..."
Rex::Ui::Text::IrbShell.new(binding).run

