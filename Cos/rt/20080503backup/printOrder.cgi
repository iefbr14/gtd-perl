#!/usr/bin/perl
# ---------------------------
#	printOrder.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use Cos::Dbh;

print "Content-type: text/plain\n\n";

my($order) = param( 'order' );
my($user) = param( 'user' );
my($pass) = param( 'pass' );

print <<"EOF";
#
# Version 0.1 printOrder.cgi
# User: $user
#
EOF
if ($user eq '') {
	print "error: missing user param\n";
	exit 0;
}

my($retailer) = sql("SELECT * FROM orders_pending WHERE orders_pending_id=219971" );

foreach( keys %{$retailer} ){
	print "$_\t$retailer->{$_}\n";
}
