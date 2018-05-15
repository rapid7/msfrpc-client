#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'msfrpc-client'

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

load('irb.rb')

IRB.setup(nil)
IRB.conf[:PROMPT_MODE]  = :SIMPLE

# Create a new IRB instance
irb = IRB::Irb.new(IRB::WorkSpace.new(binding))

# Set the primary irb context so that exit and other intrinsic
# commands will work.
IRB.conf[:MAIN_CONTEXT] = irb.context

# Trap interrupt
old_sigint = trap("SIGINT") do
  begin
    irb.signal_handle
  rescue RubyLex::TerminateLineInput
    irb.eval_input
  end
end

# Keep processing input until the cows come home...
catch(:IRB_EXIT) do
  irb.eval_input
end

trap("SIGINT", old_sigint)
