# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'khaleesi/about'

Gem::Specification.new do |spec|
  spec.name          = 'khaleesi'
  spec.version       = Khaleesi::version
  spec.authors       = [Khaleesi::author]
  spec.email         = ['lingyunxiao@qq.com']
  spec.summary       = 'Khaleesi is a static site generator that write by ruby'
  spec.description   = 'Khaleesi is a static site generator that write by ruby, supported markdown parser, multiple decorators inheritance, simple page programming, page including, page dataset configurable etc.'
  spec.homepage      = 'https://github.com/vince-styling/khaleesi'
  spec.rubyforge_project = 'khaleesi'
  spec.files = Dir['Gemfile', 'LICENSE', 'khaleesi.gemspec', 'lib/**/*.rb', 'bin/khaleesi']
  spec.executables = %w(khaleesi)
  spec.license = 'MIT (see LICENSE file)'
end