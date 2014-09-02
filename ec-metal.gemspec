# -*- encoding: utf-8 -*-
$:.push File.expand_path('lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = "ec-metal"
  s.version     = '0.0.0'
  s.authors     = ['Chef Software, Inc.']
  s.email       = ['legal@getchef.com']
  s.homepage    = "http://github.com/opscode/ec-metal"
  s.summary     = %q{Open Source software for use with Chef}
  s.description = %q{A tool for spinning up chef servers}

  s.rubyforge_project = "ec-metal"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib', 'bin']

   s.add_runtime_dependency "chef-metal", [">= 0.14.1"]
   s.add_runtime_dependency "chef-metal-vagrant", [">= 0.5.0"]
   s.add_runtime_dependency "chef-metal-fog", [">= 0.6.0"]
   s.add_runtime_dependency "cheffish", [">= 0.6.0"]
   s.add_runtime_dependency "chef", [">= 10.34.2"]
   s.add_runtime_dependency "berkshelf", [">= 3.0"]
   s.add_runtime_dependency "mixlib-shellout"
   s.add_runtime_dependency "knife-opc", [">= 0.1.0"]
end
