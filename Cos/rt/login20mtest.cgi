#!/usr/bin/perl
#######################################
#
#	name: login.cgi
#	purpose:  OpticalOnline login and configuration
#
#######################################
use DBI;
use CGI qw/:standard :cgi-lib/;
use Cos::Dbh;
my($Cgi_log) = 0;	# set to 1 to log all requests to /tmp

print "Content-type: text/plain\n\n";

my($user) = param('user');
my($pass) = param('pass');

# before this can be used to authorize users the username field has to be populated 
# with U_Username field from Users because user_id is an integer field and will pass
# 1005 when 001005 should be required for login
my($retailer) = sql("SELECT  * FROM retailer WHERE user_id=? AND password=?", $user, $pass);
unless (defined $retailer->{user_id}) {
	print "# Auth Failure.\n";
	exit 0;
}

my($Users) = sql("SELECT U_Username, U_BizName, U_ParentName, U_Type, U_Status, U_OrgPhone FROM Users WHERE U_Username=?", $user);
unless (defined $Users->{U_Username}) {
	print "# Auth Failure.\n";
	exit 0;
}
if ($Users->{U_Status} eq 'I')  {
	print "# Auth Failure.\n";
	exit 0;
}
my($LabRetailer) = sql("SELECT * FROM lab_customer_id WHERE user_id = ?", $user);
my($Lab) = sql("SELECT * FROM lab_info WHERE lab_id=?", $retailer->{lab_id});

my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time); 
$year += 1900;
$mon += 1;
my $sysdate= "$year/".substr(("0".$mon),-2)."/".substr(("0".$mday),-2); 

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


my $language = $retailer->{language} || 'en';
my $country = $retailer->{country} || 'US';

my $enableShipTo = $LabRetailer->{enableShipTo} || 'N';
my $poRequired   = $LabRetailer->{poRequired} || 'N';
my $useStdSBC	= $LabRetailer->{useStdSBC} || 'Y';
my $dateFormat	= $LabRetailer->{dateFormat} || '1';
my $enableRedo	= $LabRetailer->{enableRedo} || 'Y';
my $enableOC	= $LabRetailer->{enableOC} || 'Y';
my $enable3D = $LabRetailer->{enable3D} || 'Y';
my $eyeBridgeReq	= $LabRetailer->{eyeBridgeReq} || 'Y';
my $enableSlabOff	= $LabRetailer->{enableSlabOff} || 'Y';
my $enableReadingSV	= $LabRetailer->{enableReadingSV} || 'Y';
my $enableFrameChecks = $LabRetailer->{enableFrameChecks} || 'Y';
my $enableTraceOnly	= $LabRetailer->{enableTraceOnly} || 'Y';
my $stdLensesPanel	= $LabRetailer->{stdLensesPanel} || 'Y';
my $enableCylWarning = $LabRetailer->{enableCylWarning} || 'Y';
my $useDefaults   = $LabRetailer->{useDefaults} || 'Y';
my $defaultUncut   = $LabRetailer->{defaultUncut} || 'Y';
my $enableSpecInstWarn   = $LabRetailer->{enableSpecInstWarn} || 'Y';
my $enableDiameters   = $LabRetailer->{enableDiameters} || 'N';
my $enableDigital;
if ($user eq '003001') {
	$enableDigital='Y';
} else {
	$enableDigital   = $LabRetailer->{enableDigital} || 'N';
}
my $enableFrameData   = $LabRetailer->{enableFrameData} || 'N';
my $defaultLabSupply  = $LabRetailer->{defaultLabSupply} || 'N';
my $enableProvider  = $LabRetailer->{enableProvider} || 'N';
my $rxiTransport;
if (defined $Lab->{transport} && $Lab->{transport} eq 'mail-rxi') {
	$rxiTransport = 'Y';
} else {
	$rxiTransport = 'N';
}

my($labId) = $LabRetailer->{lab_id} || $retailer->{lab_id};


##########################################
$vars = Vars;
$vars->{ip_address} = $ENV{'REMOTE_ADDR'};
$vars->{ip_name}    = $ENV{'HTTP_HOST'};

$vars->{cgiScript}    =  "login20";
$vars->{user} =  $user;
if ($Cgi_log) {
	open(LOG, ">>/tmp/login20.log");
	print LOG "############################################\n";

	foreach $key (sort keys %ENV) {
		print LOG "# $key\t$ENV{$key}\n";
	}
	foreach $parm (sort keys %$vars) {
		print LOG "$parm\t$vars->{$parm}\n";
	}
}
#############################################
	
print <<"EOF";
#
# Version 2.0 login.cgi information
# User: $user 
# Pass: $pass
#
labId = $labId
lab_id 		= $retailer->{lab_id}
language 		= $retailer->{language}
country 		= $retailer->{country}
retailer_email = $retailer->{email}
retailer_address = $retailer->{address}
retailer_address2 = $retailer->{address2}
retailer_city = $retailer->{city}
retailer_state = $retailer->{area}
retailer_county = $retailer->{county}
retailer_zip = $retailer->{postal_code}
retailer_date = $sysdate
NPI		= $retailer->{NPI}
MID		= $retailer->{MID}
ACCT	= $retailer->{ACCT}

name 		= $Users->{U_BizName}
clientName  = $Users->{U_BizName}
clientLab   = $Users->{U_ParentName}
type 		= $Users->{U_Type}
retailer_phone = $Users->{U_OrgPhone}

StoreNum 	= $LabRetailer->{customer_id}

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
useDefaults = $useDefaults
defaultUncut = $defaultUncut
defaultLabSupply = $defaultLabSupply
enableSpecInstWarn = $enableSpecInstWarn
enableDiameters = $enableDiameters
enableFrameData = $enableFrameData
enableProvider = $enableProvider
rxiTransport = $rxiTransport
enableDigital = $enableDigital

siteColor = $Color
#set site to 'live' to turn off OpticalOnline's random color featuare sent by siteColor 
site = random

EOF
