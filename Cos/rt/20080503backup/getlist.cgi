#!/usr/bin/perl
# ---------------------------
# getlist.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::auth qw(auth_prop);

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

print <<"EOF";
#
# Version 1.0 getlist.cgi information
# User: $user 
#
EOF

auth_prop($user, $pass);

my($file, @files);

@files = <*>;

my($work) = 0;
foreach $file (@files) {
	($id,$subid,$type,$file) = split('-', $file, 4);

	++$work;
	print "file$work: $id/$subid/$type/$file\n";
}
print "files: $work\n";
