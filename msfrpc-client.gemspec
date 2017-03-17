# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'msfrpc-client/version'

Gem::Specification.new do |s|
  s.name        = 'msfrpc-client'
  s.version     = Msf::RPC::VERSION
  s.authors     = [
      'HD Moore',
      'Brent Cook'
  ]
  s.email       = [
      'x@hdm.io',
      'bcook@rapid7.com'
  ]
  s.homepage    = "http://www.metasploit.com/"
  s.summary     = %q{Ruby API for the Rapid7 Metasploit RPC service}
  s.description = %q{
   This gem provides a Ruby client API to access the Rapid7 Metasploit RPC service.
  }.gsub(/\s+/, ' ').strip

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.licenses      = ['BSD-2-Clause']

  s.add_runtime_dependency 'msgpack'
  s.add_runtime_dependency 'rex'
end
