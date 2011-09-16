# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cachetastic/adapters/memcache_pool/version"

Gem::Specification.new do |s|
  s.name        = "cachetastic-memcache-pool"
  s.version     = Cachetastic::Adapters::MemcachePool::VERSION
  s.authors     = ["Jason Wadsworth"]
  s.email       = ["jason@gazelle.com"]
  s.homepage    = ""
  s.summary     = %q{Cachetastic Memcached Adapter with Connection Pooling}
  s.description = %q{Cachetastic Memcached Adapter with Connection Pooling}

  s.rubyforge_project = "cachetastic-memcache-pool"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 2.6.0"
  s.add_development_dependency "rcov", "~> 0.9.0"

  s.add_runtime_dependency "cachetastic", "~> 3.0.0"
  s.add_runtime_dependency "memcache-client", "~> 1.8.5"
end
