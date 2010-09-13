#!/usr/bin/perl
# ---------------------------
#         order.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::auth qw(auth_user auth_cd);

my($user) = param('user');
my($pass) = param('pass');
my($file) = param('file');

my($q) = new CGI;

my($info) = auth_user($user, $pass);

auth_cd($user, $info);

my($localfile);

if (-f $file) {
	$localfile = $file;
} else {
	my(@files) = <$file-*>;

	$localfile = shift @files;
}

if (open(F, "< $localfile\0")) {
	print $q->header(-type => 'application/octet-stream',
		-Content_length => (-s $localfile),
		-attachment => $localfile);

	while (read(F, $buf, 1024)) {
		print $buf;
	}
	close(F);
} else {
	print $q->header(-type => 'text/plain',
		-status=> "404 Can't open file $file ($!)");
}
