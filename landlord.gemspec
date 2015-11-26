# -*- encoding: utf-8 -*-
$: << File.expand_path("../lib", __FILE__)
require "landlord/version"

Gem::Specification.new do |s|
  s.name = %q{landlord}
  s.version = Landlord::VERSION

  s.authors       = ["Andrew J. Ayers", "Ryan Brunner", "Brad Robertson"]
  s.summary       = %q{A Ruby gem for multitenant rails applications running on PostgreSQL}
  s.description   = %q{Landlord allows Rack applications to deal with multitenancy through PostgreSQL's scheam search path}
  s.email         = ["andy@ajayers.net"]
#XAJA|  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.homepage = %q{https://github.com/ajayers/landlord}
  s.licenses = ["MIT"]

  s.post_install_message = <<-MSG
    Landlord has been installed.
  MSG

  s.add_dependency 'activerecord',    '>= 4.2.4', '< 5.0'
  s.add_dependency 'rack',            '>= 1.6.4'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rake',         '~> 0.9'
  s.add_development_dependency 'rspec-rails',  '~> 2.14'
  s.add_development_dependency 'guard-rspec',  '~> 4.2'
  s.add_development_dependency 'capybara',     '~> 2.0'

  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'activerecord-jdbc-adapter'
    s.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
    s.add_development_dependency 'jdbc-postgres', '9.2.1002'
    s.add_development_dependency 'jruby-openssl'
  else
    s.add_development_dependency 'pg',     '>= 0.11.0'
  end
end
