# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/paquet/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-paquet"
  spec.version       = Sidekiq::Paquet::VERSION
  spec.authors       = ["ccocchi"]
  spec.email         = ["cocchi.c@gmail.com"]

  spec.summary       = "Bulk processing for sidekiq 4+"
  spec.homepage      = "https://github.com/ccocchi/sidekiq-paquet"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 4"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
