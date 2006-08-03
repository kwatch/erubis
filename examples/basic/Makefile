all = example.rb example.php example.c example.java example.scm example.pl example.js

all:  $(all)

example.rb:   example.eruby
	erubis -l ruby example.eruby > example.rb


example.php:  example.ephp
	erubis -l php example.ephp > example.php

example.c:    example.ec
	erubis -bl c example.ec > example.c

example.java: example.ejava
	erubis -bl java example.ejava > example.java

example.scm:  example.escheme
	erubis -l scheme --func=display example.escheme > example.scm
#	erubis -l scheme example.escheme > example.scm

example.pl:   example.eperl
	erubis -l perl example.eperl > example.pl

example.js:   example.ejavascript
	erubis -l javascript example.ejavascript > example.js


###----------

src = example.eruby example.ephp example.ec example.ejava example.escheme example.eperl example.ejavascript Makefile

clean:
	rm -f `ruby -e 'puts(Dir.glob("*.*") - %w[$(src)])'`
#	rm -f $(all)

compile:  a.out example.class

a.out:   example.c
	cc example.c

example.class:  example.java
	jikes example.java

output:  $(all) a.out example.class
	erubis example.eruby > example.ruby.out
	php example.php > example.php.out
	./a.out foo bar baz > example.c.out
	java example > example.java.out
	gosh example.scm > example.scm.out
#	guile example.scm > example.scm.out
	perl example.pl > example.pl.out

