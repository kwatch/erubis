= README

release::	$Release$
copyright::	$Copyright$



== About Erubis

Erubis is an implementation of eRuby. It has the following features.
* Very fast, almost three times faster than ERB and even faster than eruby
* Multi-language support (Ruby/PHP/C/Java/Scheme/Perl/Javascript)
* Auto escaping support
* Auto trimming spaces around '<% %>'
* Embedded pattern changeable (default '<% %>')
* Enable to handle Processing Instructions (PI) as embedded pattern (ex. '<?rb ... ?>')
* Context object available and easy to combine eRuby template with YAML datafile
* Print statement available
* Easy to extend and customize in subclass
* Ruby on Rails support

Erubis is implemented in pure Ruby.  It requires Ruby 1.8 or higher.

See doc/users-guide.html for details.



== Installation

* If you have installed RubyGems, just type <tt>gem install --remote erubis</tt>.

    $ sudo gem install --remote erubis

* Else install abstract[http://rubyforge.org/projects/abstract/] at first,
  and download erubis_X.X.X.tar.bz2 and install it by setup.rb.

    $ tar xjf abstract_X.X.X.tar.bz2
    $ cd abstract_X.X.X/
    $ sudo ruby setup.rb
    $ cd ..
    $ tar xjf erubis_X.X.X.tar.bz2
    $ cd erubis_X.X.X/
    $ sudo ruby setup.rb

* (Optional) It is able to merge 'lib/**/*.rb' into 'bin/erubis' by
  'contrib/inline-require' script.

    $ tar xjf erubis_X.X.X.tar.bz2
    $ cd erubis_X.X.X/
    $ cp /tmp/abstract_X.X.X/lib/abstract.rb lib
    $ unset RUBYLIB
    $ contrib/inline-require -I lib bin/erubis > contrib/erubis



== Exploring Guide

If you are exploring Eruby, see the following class at first.
* Erubis::TinyEruby (erubis/tiny.rb) --
  the most simple eRuby implementation.
* Erubis::Engine (erubis/engine.rb) --
  base class of Eruby, Ephp, Ejava, and so on.
* Erubis::Eruby (erubis/engine/eruby.rb) --
  engine class for eRuby.
* Erubis::Converter (erubis/converter.rb) --
  convert eRuby script into Ruby code.



== Benchmark

'benchmark/erubybenchmark.rb' is a benchmark script of Erubis.
Try 'ruby erubybenchmark.rb' in benchmark directory.



== License

LGPL



== Author

makoto kuwata <kwa(at)kuwata-lab.com>
