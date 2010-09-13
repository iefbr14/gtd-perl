#!/usr/bin/perl
#######################################
#
#	name: history.cgi
#	purpose:  OpticalOnline OrderHistoryCache.java
#			  retrieves partial data on
#			  all of a retailer's orders
#
#######################################
use strict;

use DBI;
use CGI qw/:standard/;
use Cos::w2 qw($dbh);
use Cos::Dbh;
use Cos::std;
use encoding "utf-8";

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

my %FORM   = Cos::w2::get_input();
my($user) = $FORM{'user'};

# User ID is valid - continue
# default date format for old versions is %b-%d-%Y (MMM-DD-YYYY)
# optional date formats controlled by a property in server.config are:
# 2=%m-%d-%YYY (MMM-DD-YYYY0; 3=%d-%m-%YYYY (DD-MMM-YYYY)
# formats 2 and 3 use the numeric %m output as an index into
# a language dependent string array and the actual display
# output is turned into an alphabetic, three-character month
my($query) = <<"EOF";
SELECT orders_pending_id,
	DATE_FORMAT(created_date, "%Y-%m-%d.%T"),
	field_client_name
FROM orders_pending 
WHERE field_acct_id=? 
ORDER BY created_date DESC
EOF

sql_item($query, $user);

sub sql_item {
	my($query, $user) = @_;

	my($CSV)      = Text::CSV->new( { binary => 1 });
	my($sth, @row);

	$sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($user)          or die "Can't execute: $query. Reason: $!";

print "#+,order_id,retailer,date_created\n";

	my($reccnt) = 0;
	while (@row = $sth->fetchrow_array()) {
		++$reccnt;
		$CSV->combine(($reccnt,@row));
		print ascii($CSV->string()), "\n";
	}
print "#=count,$reccnt\n";
}
