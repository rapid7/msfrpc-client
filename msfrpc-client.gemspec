# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'msfrpc-client/version'

Gem::Specification.new do |spec|
  spec.name        = 'msfrpc-client'
  spec.version     = Msf::RPC::VERSION
  spec.authors     = [
      'HD Moore',
      'Brent Cook'
  ]
  spec.email       = [
      'x@hdm.io',
      'bcook@rapid7.com'
  ]
  spec.homepage    = "http://www.metasploit.com/"
  spec.summary     = %q{Ruby API for the Rapid7 Metasploit RPC service}
  spec.description = %q{
   This gem provides a Ruby client API to access the Rapid7 Metasploit RPC service.
  }.gsub(/\s+/, ' ').strip

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.licenses      = ['BSD-2-Clause']

  spec.add_runtime_dependency 'msgpack', '~> 1'

  spec.add_development_dependency "bundler", '~> 1'
  spec.add_development_dependency "rake", '~> 12'
  spec.add_development_dependency "rspec", '~> 3'
end
