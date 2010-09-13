#!/usr/bin/perl
#######################################
#
#	name: history.cgi
#	purpose:  OpticalOnline OrderHistoryCache.java
#			  retrieves partial data on
#			  all of a retailer's orders
#
#######################################
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;
use utf8;
use encoding "utf-8";

my($dbh) = new Cos::Dbh;

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');
my($dateformat) = param('dateformat');

# Check the user account
my($retailer) = sql("SELECT user_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID is valid - continue
# default date format for old versions is %b-%d-%Y (MMM-DD-YYYY)
# optional date formats controlled by a property in server.config are:
# 2=%m-%d-%YYY (MMM-DD-YYYY0; 3=%d-%m-%YYYY (DD-MMM-YYYY)
# formats 2 and 3 use the numeric %m output as an index into
# a language dependent string array and the actual display
# output is turned into an alphabetic, three-character month
if($dateformat==3){
$query = <<"EOF";
SELECT orders_pending_id,field_client_name,created_date+0,
	DATE_FORMAT(created_date, "%d-%m-%Y") 
FROM orders_pending 
WHERE field_acct_id=? 
ORDER BY created_date DESC
EOF
}elsif($dateformat==2){
$query = <<"EOF";
SELECT orders_pending_id,field_client_name,created_date+0,
	DATE_FORMAT(created_date, "%m-%d-%Y") 
FROM orders_pending 
WHERE field_acct_id=? 
ORDER BY created_date DESC
EOF
}else{
$query = <<"EOF";
SELECT orders_pending_id,field_client_name,created_date+0,
	DATE_FORMAT(created_date, "%b-%d-%Y ") 
FROM orders_pending 
WHERE field_acct_id=? 
ORDER BY created_date DESC
EOF
}
print <<"EOF";
#
# Version 1.0 history.cgi information
# User: $user 
#
EOF

sql_item($query, $user);

sub sql_item {
	my($query) = shift @_;

	$sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute(@_)             or die "Can't execute: $query. Reason: $!";

	my($i) = 0;
	while (@row = $sth->fetchrow_array()) {
		++$i;
		print "item$i: ", join("\t", @row), "\n";
	}
	print "max: $i\n";
}
