# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gundog/version'

Gem::Specification.new do |spec|
  spec.name          = "gundog"
  spec.version       = Gundog::VERSION
  spec.authors       = ["Alexander Huber"]
  spec.email         = ["alih83@gmx.de"]

  spec.summary       = %q{Lightweight Ruby & RabbitMQ background worker framework}
  spec.description   = "Ruby & RabbitMQ background worker framework "\
                       "based on eventmachine and celluloid"
  spec.homepage      = "https://github.com/alihuber/gundog"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         =
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake",    "~> 10.0"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "activesupport", "4.2.6"
  spec.add_development_dependency "activerecord-nulldb-adapter", "0.3.2"
  spec.add_development_dependency "simplecov", "0.11.2"

  spec.add_dependency "bunny",        "~> 2.3"
  spec.add_dependency "celluloid",    "~> 0.17"
  spec.add_dependency "serverengine", "~> 1.6"
  spec.add_dependency "rails",        "4.2.6"
end
