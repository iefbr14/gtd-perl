#!/usr/bin/perl
#######################################
#
#	name: login.cgi
#	purpose:  OpticalOnline login
#			  and configuration
#
#######################################
use utf8;
use encoding "utf-8";
use DBI;
use CGI qw/:standard/;
use Cos::Dbh;

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

open(T, ">>/tmp/log");
print T "User:$user, pass:$pass.\n";
close(T);


#foreach $key (sort keys %ENV) {
#	print "# $key: $ENV{$key}\n";
#}

# Check the user account
my($retailer) = sql("SELECT user_id,bizname,method,lab_id,mono,usa FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
        # User ID not valid
	print "# Auth Failure.\n";
	print "pass_feedback=$pass";
	exit 0;
}

# User ID and Password are valid - continue
my($Users) = sql("SELECT U_BizName, U_ParentName, U_Type FROM Users WHERE U_Username=?", $user);
my($Lab) = sql("SELECT lab_id, customer_id, poRequired, enableShipTo FROM lab_customer_id WHERE user_id = ?", $user);

my(@Color) = (
	'b96788',
	'FF0000',
	'00FF00',
	'0000FF',
	'00FFFF',
	'FFFF00',
	'FF00FF',
	'888888',
);

my($id) = time % scalar(@Color);
$Color = $Color[$id];
$Color = sprintf("%02x%02x%02x", rc(), rc(), rc());

sub rc {
	return int(rand(128))+128;
}

$Users->{U_Type} = 'R' if $Users->{U_Type} eq 'F';	# old OO versions only handle 'R'

my $enableShipTo = $Lab->{enableShipTo} || 'N';
my $poRequired   = $Lab->{poRequired} || 'N';
my($labId) = $Lab->{lab_id} || $retailer->{lab_id};

print <<"EOF";
#
# Version 1.0 login.cgi information
# User: $user 
# Pass: $pass
#
pass_feedback = $pass
lab_id = $retailer->{lab_id}
mono = $retailer->{mono}
usa = $retailer->{usa}

name = $Users->{U_BizName}
clientName  = $Users->{U_BizName}
clientLab   = $Users->{U_ParentName}
type = $Users->{U_Type}

labId = $labId
StoreNum = $Lab->{customer_id}
enableShipTo = $enableShipTo
poRequired = $poRequired
enablePatientInfo = f

siteColor = $Color

delivery = 1
site = martin
EOF
