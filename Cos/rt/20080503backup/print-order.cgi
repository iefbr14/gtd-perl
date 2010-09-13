#!/usr/bin/perl
# ---------------------------
#      print-order.cgi
# ---------------------------

use DBI;
use CGI qw/:standard/;
use Cos::Dbh;
use Cos::DbPrintTicket;

my($dbh) = new Cos::Dbh;

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

# User account is valid - continue
my($order) = param('order');

$query = <<"EOF";
SELECT *
,DATE_FORMAT(created_date, "%b-%d-%Y") as date_c
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(promised_date,'%m%d%y') as datePromised
,DATE_FORMAT(promised_date,'%h:%i%p') as timePromised

FROM orders_pending 
WHERE orders_pending_id=?
EOF

my($ref) = sql($query, $order);

Cos::DbPrintTicket::print($ref);
