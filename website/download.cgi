#!/usr/local/bin/php
<?php

/*
 * redirecto url
 */
#$redirect_url = "http://sourceforge.net/projects/kwaff/";
$redirect_url = "http://rubyforge.net/projects/erubis/";


/*
 *  counter increment and return value
 */
function counter_incr(&$basedir, &$filename) {
    $filename = preg_replace('/\.\./', '_', $filename);     // for security
    if (!is_dir($basedir) && !mkdir($basedir)) {
        die($basedir);
    }
    $dir = dirname("${basedir}/${filename}");
    if (!is_dir($dir) && !mkdir_p($dir, 0700)) {
        die("cannot create '${dir}'");
    }
    if (! ($f = fopen("${basedir}/${filename}", "a+"))) {
        die("${basedir}/${filename}");
    }
    flock($f, LOCK_EX);
    rewind($f);
    $s = fread($f, 1024);
    $n = 1 + $s;
    ftruncate($f, 0);
    fwrite($f, "$n");
    //flock($f, LOCK_UN);
    fclose($f);
    return $n;
}


/*
 * main program
 */
// increment counter
$docroot      = $_SERVER['DOCUMENT_ROOT'];
$basedir_data = dirname($docroot) . "/Counter";
$request_uri  = $_SERVER['REQUEST_URI'];
$filepath     = preg_replace('/^http:\/\/[^\/]+/', '', $request_uri);
counter_incr($basedir_data, $filepath);

// redirect
header("Location: ${redirect_url}");

?>
<html>
<body>
Jump to <a href="<?php echo htmlspecialchars($redirect_url); ?>"><?php echo htmlspecialchars($redirect_url); ?></a>
</body>
</html>
