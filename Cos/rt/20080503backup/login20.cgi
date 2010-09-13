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


# Check the user account
my($retailer) = sql("SELECT user_id,bizname,lab_id FROM retailer WHERE user_id=? AND password=?", $user, $pass);

unless (defined $retailer->{user_id}) {
    # User ID not valid
	print "# Auth Failure.\n";
	exit 0;
}

# User ID and Password are valid - continue
my($Users) = sql("SELECT U_BizName, U_ParentName, U_Type FROM Users WHERE U_Username=?", $user);
my($Lab) = sql("SELECT * FROM lab_customer_id WHERE user_id = ?", $user);

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

my $useStdSBC	= $Lab->{useStdSBC} || 'Y';
my $dateFormat	= $Lab->{dateFormat} || '1';
my $enableRedo	= $Lab->{enableRedo} || 'Y';
my $enableOC	= $Lab->{enableOC} || 'Y';
my $enable3D = $Lab->{enable3D} || 'Y';
my $eyeBridgeReq	= $Lab->{eyeBridgeReq} || 'Y';
my $enableSlabOff	= $Lab->{enableSlabOff} || 'Y';
my $enableReadingSV	= $Lab->{enableReadingSV} || 'Y';
my $enableFrameChecks = $Lab->{enableFrameChecks} || 'Y';
my $enableTraceOnly	= $Lab->{enableTraceOnly} || 'Y';
my $stdLensesPanel	= $Lab->{stdLensesPanel} || 'Y';
my $enableCylWarning = $Lab->{enableCylWarning} || 'Y';
# when the lab_customer_id table is expanded with the following fields
# this condition for Lab187 can be removed.
if ($Lab->{lab_id} == 187) {
	$useStdSBC	= 'N';
	$dateFormat	= '3';
	$enableRedo	= 'N';
	$enableOC	= 'N';
	$enable3D = 'N';
	$eyeBridgeReq	= 'N';
	$enableSlabOff	= 'N';
	$enableReadingSV	= 'N';
	$enableFrameChecks = 'N';
	$enableTraceOnly	= 'N';
	$stdLensesPanel	= 'Y';
	$enableCylWarning = 'N';
}

my($labId) = $Lab->{lab_id} || $retailer->{lab_id};

print <<"EOF";
#
# Version 1.0 login.cgi information
# User: $user 
# Pass: $pass
#
labId = $labId
lab_id 		= $retailer->{lab_id}

name 		= $Users->{U_BizName}
clientName  = $Users->{U_BizName}
clientLab   = $Users->{U_ParentName}
type 		= $Users->{U_Type}

StoreNum 	= $Lab->{customer_id}

enableShipTo = $enableShipTo
poRequired 	= $poRequired
useStdSBC	= $useStdSBC
dateFormat	= $dateFormat
enableRedo	= $enableRedo
enableOC	= $enableOC
enable3D	= $enable3D
eyeBridgeReq	= $eyeBridgeReq
enableSlabOff	= $enableSlabOff
enableReadingSV	= $enableReadingSV
enableFrameChecks = $enableFrameChecks
enableTraceOnly	= $enableTraceOnly
stdLensesPanel	= $stdLensesPanel
enableCylWarning = $enableCylWarning

siteColor = $Color
#set site to 'live' to turn off OpticalOnline's random color featuare sent by siteColor 
site = random

EOF
