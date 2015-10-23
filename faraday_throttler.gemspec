# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faraday_throttler/version'

Gem::Specification.new do |spec|
  spec.name          = "faraday_throttler"
  spec.version       = FaradayThrottler::VERSION
  spec.authors       = ["Ismael Celis"]
  spec.email         = ["ismaelct@gmail.com"]

  spec.summary       = %q{Redis-backed request throttler requests to protect backend APIs against request stampedes}
  spec.description   = %q{Configure how often you want to hit backend APIs, and fallback responses to keep clients happy}
  spec.homepage      = "https://github.com/ismasan/faraday_throttler"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 0.9.1"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
