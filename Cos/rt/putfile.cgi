#!/usr/bin/perl
# ---------------------------
#         order.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use MIME::Base64;
use Cos::auth qw(auth_prop);

print "Content-type: text/plain\n\n";

my($q) = new CGI;

my($user)    = $q->param('user');
my($pass)    = $q->param('pass');
my($type)    = $q->param('type');
my($dest)    = $q->param('dest');
my($member)  = $q->param('member');
my($group)   = $q->param('group');
my($version) = $q->param('version');

auth_prop($user, $pass);

if ($user eq '') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: missing user parm\n";
	exit 0;
}
if ($type eq '') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: missing type parm\n";
	exit 0;
}

if ($dest eq '') {
	$dest = 'default';
#	print $q->header(-type => 'text/plain');
#	print "status: fail\nerror: missing dest parm\n";
#	exit 0;
}

if ($member eq '') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: missing member parm\n";
	exit 0;
}

if ($group eq '') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: missing group parm\n";
	exit 0;
}

if ($version eq '') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: missing version parm\n";
	exit 0;
}

if ($version ne '0.9.3') {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: version not supported\n";
	exit 0;
}

if (! -d "/home/cos/recv/$user") {
	mkdir("/home/cos/recv/$user", 0777); 
}

if (! -d "/home/cos/recv/$user/$dest") {
	mkdir("/home/cos/recv/$user/$dest", 0700); 
}

if (! -d "/home/cos/recv/$user/$dest/$type") {
	mkdir("/home/cos/recv/$user/$dest/$type", 0700); 
}

if (!chdir("/home/cos/recv/$user/$dest/$type")) {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: No receive directory for $user/$dest/$type\n";
	exit 0;
}

$parm = $q->param('file');
$fd = $q->upload('file');
$filename = "$group-$member-$parm";

# Copy a binary file to somewhere safe
$filename =~ s/^[^a-z0-9-.]*$//i;

unless (open (OUTFILE,"> $filename\0")) {
	print $q->header(-type => 'text/plain');
	print "status: fail\nerror: can't create $filename ($!)\n";
	exit 0;
}
while ($bytesread=read($fd, $buffer, 1024) > 0) {
	print OUTFILE $buffer;
}
close(OUTFILE);

print "Content-type: text/plain\n\nstatus: ok\n";
print "file: $filename\n";
print "dest: $dest\n";
print "type: ", $q->uploadInfo($parm)->{'Content-Type'}, "\n";

