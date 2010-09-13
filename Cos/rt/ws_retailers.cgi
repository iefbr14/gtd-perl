#!/usr/bin/perl
###########################################################
#
#	name:  list_retail.cgi
#	purpose:
#	links from:  list_accounts.cgi, list_labs.cgi, list_retail.cgi
#	links to:  change_account.cgi, list_retail.cgi
#	database tables: Users, retailer, lab_customer_id
#
###########################################################
use strict;
use encoding "utf-8";
use Cos::w2 qw($dbh);
use Cos::std;
use Text::CSV;

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

# Grab the form input
my %FORM   = Cos::w2::get_input();
my($Lab) = $FORM{'lab'};

# Some local variables
my %Retail;

# Start the HTML page

# populate the %Retail hash with retailer.user_id as the key (for one lab or all labs)
if ($Lab) {
	get_retail_list("SELECT user_id FROM retailer WHERE lab_id=$Lab", 0x02);
} else {
	Cos::w2::user_error("No lab specified");
}

my($CSV)      = Text::CSV->new( { binary => 1 });

$CSV->combine(
	"#+",
	"retailer_id",
	"name",
	"lab_id",
	"business name",
	"Parent/Lab Name",
	"Type",
	"Orders",
	"Problems",
);
print $CSV->string(), "\n";

my($acct, $retail);
my($Username, $AcctName, $LabName, $Count, $Problem, $Type, $RLab, $RNum, $Uid);

my($Reccnt) = 0;

# For each %Retail key (retailer.user_id) output a row of data
foreach $retail (sort { $a <=> $b } keys %Retail) {
	$Problem  = '';
	&get_users($retail);		# Fills in $Type=Users.U_Type, $Uid=Users.U_UserId,
								#    $Username=Users.U_Username, $AcctName=Users.U_ParentName, $Problem
	&get_retail($retail);		# Fills in $RLab=retailer.lab_id, $RNum=retailer.store_id,
								#    $LabName=retailer.bizname, $Count=retailer.order_cnt, $Problem
	
	++$Reccnt;
	$CSV->combine(
		$Reccnt,
		$retail,
		$Username,
		$RLab,
		$LabName,
		$AcctName,
		$Type,
		$Count,
		$Problem
	);
        print ascii($CSV->string()), "\n";
}
print "#=$Reccnt\n";

###########################################################
#
#	subroutine name:  get_retail_list
#	purpose: populates the %Retail hash with key/value
#		pairs. the value is bitwise OR'd with $mode
#		to produce an indication of where the key was found
#		if value=2 - key found in retailer xor Users table only
#		if value=4 - key found in Users table only
#		if value=6 - key found in both tables
#
###########################################################

sub get_retail_list {
	my($query, $mode) = @_;

	my $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute                    or die "Can't execute: $query. Reason: $!";

	while( (($retail) = $sth->fetchrow_array()) ) {
		$Retail{$retail} |= $mode;
	}
}


###########################################################
#
#	subroutine name:  get_users
#	purpose: the parameter passed is a retailer.user_id
#		this sub then checks if there is a linked record
#		in the Users table (Users.U_InfoId). If no record
#		was found it reports the problem by putting 'No
#		Users' into $Problem. If more than one record
#		was found it reports 'Dup Users' and adds
#		how many extras were found.
#
###########################################################

sub get_users {
	
	# Some local variables
	my($retail) = @_;
	my($query) = "SELECT * FROM Users WHERE U_InfoId=?"
				. " AND (U_Type='R' OR U_Type='W' OR U_Type='F')";
	my($bogus) = 0;

	my $sth = $dbh->prepare($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($retail)          or die "Can't execute: $query. Reason: $!";
	my($ref) = $sth->fetchrow_hashref();

	# No Users record found
	unless (defined $ref) {
		$Type     = '';
		$Uid      = '';
		$Username = '';
		$AcctName = '';
		$Problem   .= 'No Users record ';
		return;
	}
	
	# Fill in what was retrieved
	$Type     = $ref->{U_Type};
	$Uid      = $ref->{U_UserId};
	$Username = $ref->{U_Username};
	$AcctName = $ref->{U_ParentName};			

	# If there was more than one row retrieved then we have duplicates
	while ($sth->fetchrow_hashref()) {
		++$bogus;
	}
	if ($bogus) {
		$Problem .= "Dup Users records($bogus) ";
	}
	$sth->finish;
}


###########################################################
#
#	subroutine name:  get_retail
#	purpose:
#
###########################################################

sub get_retail {
	
	my($retail) = @_;
	my($bogus) = 0;
	my($query) = "SELECT * FROM retailer WHERE user_id = ?";

	my $sth = $dbh->prepare($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($retail)          or die "Can't execute: $query. Reason: $!";
	my($ref) = $sth->fetchrow_hashref();
	
	# No retail record found
	unless (defined $ref) {
		$RLab    = '';
		$RNum    = '';
		$LabName = '';
		$Count   = '';
		$Problem   .= 'No retailer record ';
		return;
	}
	
	# Fill in what was retrieved
	$RLab    = $ref->{lab_id};
	$RNum    = $ref->{store_id};
	$LabName = $ref->{bizname};
	$Count   = $ref->{order_cnt};

	# If there was more than one row retrieved then we have duplicates
	while ($sth->fetchrow_hashref()) {
		++$bogus;
	}
	if ($bogus) {
		$Problem .= "Dup retailer record($bogus) ";
	}
	
	$sth->finish;
}
