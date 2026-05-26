lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiera/backend/eyaml/encryptors/age/version'

Gem::Specification.new do |gem|
  gem.name          = 'hiera-eyaml-age'
  gem.version       = Hiera::Backend::Eyaml::Encryptors::AgeVersion::VERSION
  gem.description   = 'age encryptor for use with hiera-eyaml'
  gem.summary       = 'Encryption plugin for hiera-eyaml backend for Hiera'
  gem.authors       = ['IAS Network']
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/theias/hiera-eyaml-age'
  gem.metadata      = {
    'source_code_uri'   => 'https://github.com/theias/hiera-eyaml-age',
    'changelog_uri'     => 'https://github.com/theias/hiera-eyaml-age/blob/main/CHANGELOG.md',
    'bug_tracker_uri'   => 'https://github.com/theias/hiera-eyaml-age/issues',
  }

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 3.0'
  gem.add_dependency('hiera-eyaml', '~> 4.2.0')
end
