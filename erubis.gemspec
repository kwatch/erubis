#!/usr/bin/ruby

###
### $Rev$
### $Release$
### $Copyright$
###

require 'rubygems'

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "erubis"
  s.author      = "kwatch"
  s.version     = ("$Release$" =~ /[\.\d]+/) && $&
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://rubyforge.org/projects/erubis"
  s.summary     = "a fast and extensible eRuby implementation which supports multi-language"
  s.description = <<-'END'
  Erubis is an implementation of eRuby and has the following features:
  * Very fast (about three times faster than ERB)
  * Multi-language support (Ruby/PHP/C/Java/Scheme/Perl/Javascript)
  * Auto trimming spaces around '<% %>'
  * Auto sanitizing
  * Change embedded pattern (default '<% %>')
  * Context object available
  * Easy to expand in subclass
  END

  ## files
  files = []
  files += Dir.glob('lib/**/*')
  files += Dir.glob('bin/*')
  files += Dir.glob('examples/**/*')
  files += Dir.glob('test/*.rb')
  files += %w[doc/users-guide.html doc/docstyle.css]
  files += %w[README.txt ChangeLog COPYING setup.rb]
  files += Dir.glob('contrib/*')
  files += Dir.glob('benchmark/*')
  files += Dir.glob('doc-api/**/*')
  s.files       = files
  s.executables = ['erubis']
  s.bindir      = 'bin'
  s.test_file   = 'test/test.rb'
  s.add_dependency('abstract', ['>= 1.0.0'])
end

# Quick fix for Ruby 1.8.3 / YAML bug   (thanks to Ross Bamford)
if (RUBY_VERSION == '1.8.3')
  def spec.to_yaml
    out = super
    out = '--- ' + out unless out =~ /^---/
    out
  end
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
