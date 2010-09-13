#!/usr/bin/perl
# ---------------------------
# getdone.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::auth qw(auth_prop);

my($user) = param('user');
my($pass) = param('pass');
my($group) = param('group');

print <<"EOF";
Content-type: text/plain

#
# Version 1.0 getdone.cgi information
# User: $user 
#
EOF

auth_prop($user, $pass);

my($file, @files);
my($cnt) = 0;

my(@files) = <$group-*>;

foreach $file (@files) {
	if (unlink($file)) {
		++$cnt;
		print "ok-$cnt: $file\n";
	} else {
		print "error: Can't remove $file ($!)\n";
	}
}

print "ok: $cnt removed\n";
