======
README
======

This directory contains helper CGI script and files for Apache web server.
Using these files, it is able to publish *.rhtml as *.html under Apache.

* index.cgi   :  CGI script
* _htaccess   :  .htaccess file for Apache
* index.rhtml :  Example eRuby script


Installation
------------

Steps to install:

    ### install Erubis
    $ tar xzf erubis-X.X.X.tar.gz
    $ cd erubis-X.X.X/
    $ ruby setup.py install
    ### copy files to ~/public_html
    $ mkdir -p ~/public_html
    $ cp public_html/_htaccess   ~/public_html/.htaccess
    $ cp public_html/index.cgi   ~/public_html/
    $ cp public_html/index.rhtml ~/public_html/
    ### add executable permission to index.cgi
    $ chmod a+x ~/public_html/index.cgi
    ### edit .htaccess
    $ vi ~/public_html/.htaccess
    ### (optional) edit index.cgi to configure
    $ vi ~/public_html/index.cgi


Edit ~/public_html/.htaccess and modify user name.

~/public_html/.htaccess:

    ## enable mod_rewrie
    RewriteEngine on
    ## deny access to *.rhtml and *.cache
    #RewriteRule \.(rhtml|cache)$ - [R=404,L]
    RewriteRule \.(rhtml|cache)$ - [F,L]
    ## rewrite only if requested file is not found
    RewriteCond %{SCRIPT_FILENAME} !-f
    ## handle request to *.html and directories by index.cgi
    RewriteRule (\.html|/|^)$ /~{{*username*}}/index.cgi
    #RewriteRule (\.html|/|^)$ index.cgi


After these steps, *.rhtml will be published as *.html.
For example, if you access to http:host.domain/~username/index.html
(or http://host.domain/~username/), file ~/public_html/index.rhtml
will be displayed.
