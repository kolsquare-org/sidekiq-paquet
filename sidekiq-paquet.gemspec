# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/paquet/version'

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-paquet"
  spec.version       = Sidekiq::Paquet::VERSION
  spec.authors       = ["Kolsquare Team"]
  spec.email         = ["itops@kolsquare.com"]

  spec.summary       = "Bulk processing for sidekiq"
  spec.homepage      = "https://github.com/kolsquare-org/sidekiq-paquet/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 7"
  spec.add_dependency "concurrent-ruby"

  spec.required_ruby_version = ">= 3.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-rake"
end
