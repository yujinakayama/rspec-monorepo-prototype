# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rspec/mocks/version"

Gem::Specification.new do |s|
  s.name        = "rspec-mocks"
  s.version     = RSpec::Mocks::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Steven Baker", "David Chelimsky", "Myron Marston"]
  s.email       = "rspec@googlegroups.com"
  s.homepage    = "http://github.com/rspec/rspec-mocks"
  s.summary     = "rspec-mocks-#{RSpec::Mocks::Version::STRING}"
  s.description = "RSpec's 'test double' framework, with support for stubbing and mocking"

  s.rubyforge_project  = "rspec"

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += %w[README.md License.txt Changelog.md .yardopts .document]
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.required_ruby_version = '>= 1.8.7'

  private_key = File.expand_path('~/.gem/rspec-gem-private_key.pem')
  if File.exists?(private_key)
    s.signing_key = private_key
    s.cert_chain = [File.expand_path('~/.gem/rspec-gem-public_cert.pem')]
  end

  if RSpec::Mocks::Version::STRING =~ /[a-zA-Z]+/
    # pin to exact version for rc's and betas
    s.add_runtime_dependency "rspec-support", "= #{RSpec::Mocks::Version::STRING}"
  else
    # pin to major/minor ignoring patch
    s.add_runtime_dependency "rspec-support", "~> #{RSpec::Mocks::Version::STRING.split('.')[0..1].concat(['0']).join('.')}"
  end

  s.add_development_dependency 'rake',     '~> 10.0.0'
  s.add_development_dependency 'cucumber', '~> 1.1.9'
  s.add_development_dependency 'aruba',    '~> 0.5'
end
