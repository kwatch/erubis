#!/usr/bin/ruby

###
### $Release: $
### $Copyright$
###

require 'rubygems' unless defined?(Gem)

spec = Gem::Specification.new do |s|
  ## package information
  s.name        = "erubis"
  s.author      = "makoto kuwata"
  s.email       = "kwa(at)kuwata-lab.com"
  s.version     = "$Release$"
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "http://www.kuwata-lab.com/erubis/"
  s.summary     = "a fast and extensible eRuby implementation which supports multi-language"
  s.rubyforge_project = 'erubis'
  s.description = <<-'END'
  Erubis is an implementation of eRuby and has the following features:

  * Very fast, almost three times faster than ERB and about 10% faster than eruby.
  * Multi-language support (Ruby/PHP/C/Java/Scheme/Perl/Javascript)
  * Auto escaping support
  * Auto trimming spaces around '<% %>'
  * Embedded pattern changeable (default '<% %>')
  * Enable to handle Processing Instructions (PI) as embedded pattern (ex. '<?rb ... ?>')
  * Context object available and easy to combine eRuby template with YAML datafile
  * Print statement available
  * Easy to extend and customize in subclass
  * Ruby on Rails support
  END

  ## files
  files = []
  files += Dir.glob('lib/**/*')
  files += Dir.glob('bin/*')
  files += %w[README.txt MIT-LICENSE setup.rb]
  files += Dir.glob('contrib/**/*')
  s.files       = files
  s.executables = ['erubis']
  s.bindir      = 'bin'
  #s.add_dependency('abstract', ['>= 1.0.0'])
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
  #Gem::manage_gems
  #Gem::Builder.new(spec).build
  require 'rubygems/gem_runner'
  Gem::GemRunner.new.run ['build', '$(project).gemspec']
end

spec
