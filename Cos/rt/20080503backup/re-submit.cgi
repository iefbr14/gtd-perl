#!/usr/bin/perl
#######################################
#
#	name: re-submit.cgi
#	purpose:  OpticalOnline changes the
#			  requested order's status
#			  to M
#
#######################################
use strict;
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# Check the user account
my($retailer) = sql("SELECT user_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);


unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
my($dbh) = new Cos::Dbh;

my($order) = param('order');

my($ref) = sql("SELECT instText FROM orders_pending WHERE orders_pending_id=?", $order);
my($instructions) = $ref->{instText};

$instructions =~ s/\s+$//;
$instructions .= " *RESUBMIT*" if length($instructions) < 243;
 
my($query) = <<"EOF";
UPDATE orders_pending
SET status='M', instText=? 
WHERE orders_pending_id=?
EOF
 
sql($query, $instructions, $order);

print <<"EOF";
#
# Version 1.0 re-order.cgi information
#
order: $order
status: ok
EOF
