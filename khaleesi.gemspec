lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'khaleesi/about'

Gem::Specification.new do |spec|
  spec.name          = 'khaleesi'
  spec.version       = Khaleesi::version
  spec.authors       = [Khaleesi::author]
  spec.date          = [Khaleesi::date]
  spec.email         = ['lingyunxiao@qq.com']
  spec.summary       = [Khaleesi::summary]
  spec.description   = 'Khaleesi is a blog-aware or documentation-aware static site generator write in Ruby, supports markdown parser, series of decorators wrapping, code syntax highlighting, simple page script programming, page including, dataset traversing etc.'
  spec.homepage      = [Khaleesi::site]
  spec.rubyforge_project = 'khaleesi'
  spec.files = Dir['Gemfile', 'LICENSE', 'khaleesi.gemspec', 'lib/**/*.rb', 'bin/khaleesi']
  spec.executables = %w(khaleesi)
  spec.license = 'MIT (see LICENSE file)'
end