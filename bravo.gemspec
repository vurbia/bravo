# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bravo/version'

Gem::Specification.new do |gem|
  gem.name          = "bravo"
  gem.version       = Bravo::VERSION
  gem.authors       = ["Leandro Marcucci"]
  gem.email         = ["leanucci@gmail.com"]
  gem.description   = %q{Adaptador para el Web Service de Facturacion Electronica de AFIP}
  gem.summary       = %q{Adaptador WSFE}
  gem.homepage      = "http://github.com/leanucci/bravo"
  gem.date          = %q(2011-03-14)

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency(%q<savon>, ["~> 0.7.8"])
  gem.add_runtime_dependency(%q<thor>, ["~> 0.16.0"])
  gem.add_development_dependency(%q<debugger>, ["~> 1.3.0"])
  gem.add_development_dependency(%q<rspec>, ["~> 2.12.0"])
  gem.add_development_dependency(%q<rake>, ["~> 10.0.3"])
end