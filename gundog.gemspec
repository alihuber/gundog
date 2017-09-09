# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gundog/version"

Gem::Specification.new do |spec|
  spec.name          = "gundog"
  spec.version       = Gundog::VERSION
  spec.authors       = ["Alexander Huber"]
  spec.email         = ["alih83@gmx.de"]

  spec.summary       = %q{Lightweight Ruby & RabbitMQ background worker framework}
  spec.description   = "Ruby & RabbitMQ background worker framework "\
                       "based on bunny, serverengine and celluloid"
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
  spec.executables   = "gundog"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake",  "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "activerecord-nulldb-adapter", "0.3.7"
  spec.add_development_dependency "simplecov", "0.15.0"

  spec.add_dependency "bunny",        "~> 2.7"
  spec.add_dependency "celluloid",    "~> 0.17"
  spec.add_dependency "serverengine", "~> 2.0"
  spec.add_dependency "net-ping"
end
