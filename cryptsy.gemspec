$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'cryptsy/version'

Gem::Specification.new do |s|
  s.name = 'cryptsy'
  s.version = Cryptsy::VERSION
  s.author = 'Ian Unruh'
  s.email = 'ianunruh@gmail.com'
  s.license = 'MIT'
  s.homepage = 'https://github.com/ianunruh/cryptsy'
  s.description = 'API client for interacting with Cryptsy'
  s.summary = 'API client for interacting with Cryptsy'

  s.files = Dir['LICENSE', 'README.md', 'lib/**/*']
  s.test_files = Dir['spec/**/*']
  s.require_path = 'lib'

  s.add_dependency 'faraday'
  s.add_dependency 'hashie'
end
