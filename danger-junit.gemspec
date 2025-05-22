# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'junit/gem_version'

Gem::Specification.new do |spec|
  spec.name          = 'danger-junit'
  spec.version       = Junit::VERSION
  spec.authors       = ['Orta Therox']
  spec.email         = ['orta.therox@gmail.com']
  spec.description   = 'Get automatic inline test reporting for JUnit-conforming XML files.'
  spec.summary       = 'Get automatic inline test reporting for JUnit-conforming XML files'
  spec.homepage      = 'https://github.com/orta/danger-junit'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7'

  spec.files = `git ls-files`.lines(chomp: true)
  spec.executables = spec.files.grep(%r{\Abin/}).map(&File.method(:basename))
  spec.test_files = spec.files.grep(%r{\A(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'danger', '>= 9.0'
  spec.add_runtime_dependency 'ox', '~> 2.14'

  # So we can run our specs with junit
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6'

  # General ruby development
  spec.add_development_dependency 'bundler', '>= 2.2'
  spec.add_development_dependency 'rake', '>= 13.0'

  # Testing support
  spec.add_development_dependency 'rspec', '~> 3.4'

  # Linting code and docs
  spec.add_development_dependency 'rubocop', '>= 1.45'
  spec.add_development_dependency 'yard', '>= 0.9', '< 1.0'

  # Makes testing easy via `bundle exec guard`
  spec.add_development_dependency 'guard', '~> 2.18'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'

  # If you want to work on older builds of ruby
  spec.add_development_dependency 'listen', '~> 3.7'

  # This gives you the chance to run a REPL inside your test
  # via
  #    binding.pry
  # This will stop test execution and let you inspect the results
  spec.add_development_dependency 'pry', '~> 0.14'
end
