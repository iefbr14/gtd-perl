#!/usr/bin/perl
# ---------------------------
#         labid.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use Cos::Dbh;

my($dbh) = new Cos::Dbh;

print "Content-type: text/plain\n\n";

#foreach $key (sort keys %ENV) {
#	print "# $key: $ENV{$key}\n";
#}

# Check the User ID
my($user) = param('user');
my($pass) = param('pass');

my($retailer) = sql("SELECT user_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User account is valid - continue

my($lab) = param('name');

$lab =~ s/ot$//;

my($info) = sql("SELECT lab_id FROM lab_info WHERE mbox=?", $lab);

unless (defined $info->{lab_id}) {
	print "# Not found.\n";
	exit 0;
}

print <<"EOF";
$info->{lab_id}
EOF
