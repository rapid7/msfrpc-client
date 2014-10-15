# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'msfrpc-client'
  s.version     = '1.0.3'
  s.authors     = [
      'HD Moore'
  ]
  s.email       = [
      'hdm@rapid7.com'
  ]
  s.homepage    = "http://www.metasploit.com/"
  s.summary     = %q{Ruby API for the Rapid7 Metasploit Pro RPC service}
  s.description = %q{
   This gem provides a Ruby client API to access the Rapid7 Metasploit Pro RPC service.
  }.gsub(/\s+/, ' ').strip

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.licenses      = ['BSD-2-Clause']

  s.add_runtime_dependency 'msgpack', '~> 0.5.8', '>= 0.5.8'
  s.add_runtime_dependency 'librex', '~> 0.0.70','>= 0.0.70'
end
