$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'ec-metal'
  s.version     = '0.0.0'
  s.date        = '2014-08-27'
  s.summary     = "Sets up a chef server either open source or enterprise"
  s.description = "Sets up a chef server either open source or enterprise"
  s.authors     = ["Irving Popovetsky", "Jeremiah Snapp", "Patrick Wright", "Jessica Mink"]
  s.email       = 'irving@getchef.com'
  s.files       = ["lib/ec_metal.rb"]
  s.homepage    =
    'https://github.com/opscode/ec-metal'
  s.license       = 'MIT'
end
