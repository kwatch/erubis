.SUFFIXES: .class .java .xhtml

T = ExamplePage

execute:  $T.class
	java $T

.java.class:
	javac -source 1.5 $<

$T.java:    $T.xhtml
	erubis -bxl java --pi=java --escapefunc='escapeXml' $< > $@


clean:
	rm -f $T.java $T.class my/*.class

