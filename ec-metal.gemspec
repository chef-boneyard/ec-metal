$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'ec-metal'
  s.version     = '0.0.0'
  s.date        = '2014-08-27'
  s.summary     = "Sets up a chef server either open source or enterprise"
  s.description = "Sets up a chef server either open source or enterprise"
  s.authors     = ["Chef Software Inc"]
  s.email       = 'legal@getchef.com'
j s.files       = ["lib/ec_metal.rb"]
  s.require_paths = ['lib']
  s.homepage    =
    'https://github.com/opscode/ec-metal'
  s.license       = 'MIT'
end
