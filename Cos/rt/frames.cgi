#!/usr/bin/perl
#######################################
#
#	name: frames.cgi
#	purpose:  OpticalOnline retrieves
#			  frame data from the frame table
#
#######################################
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;
use utf8;
use encoding "utf-8";

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# Check the user account
my($retailer) = sql("SELECT user_id,lab_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);
unless (defined $retailer->{user_id}) {
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
my($lab) = param('lab');
my($lab_id) = $retailer->{lab_id};

$lab = $lab_id if $lab eq '';

my($dbh) = new Cos::Dbh;

$query = "SELECT upc,vendorName,model,color,eye,bridge,a,b,ed,dbl ". 
			"FROM frames WHERE  labID=$lab and status='L' ORDER BY upc";
$sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
$sth->execute  or die "Can't execute: $query. Reason: $!";

my($i) = 0;
while (@row = $sth->fetchrow_array()) {
	++$i;
	print "item$i: ", join("\t", @row), "\n";
}
print "max: $i\n";
