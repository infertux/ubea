# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "ubea"
  spec.version       = "1.0.0"
  spec.authors       = ["Cédric Félizard"]
  spec.email         = ["cedric@felizard.fr"]
  spec.summary       = 'Unified Bitcoin Exchange API'
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/infertux/ubea"
  spec.license       = "AGPLv3+"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "retryable", ">= 1.3.6"
  spec.add_dependency "addressable", ">= 2.3.6"
  spec.add_dependency "faraday", ">= 0.9.0"

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", ">= 3.1"
  spec.add_development_dependency "simplecov", ">= 0.9"
  spec.add_development_dependency "rubocop", ">= 0.27"
end
