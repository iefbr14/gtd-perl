#!/usr/bin/perl
###########################################################
#
#	name: list_labs.cgi
#	purpose: List/Verify Labs
#	links from:
#	links to:
#	database tables:
#
###########################################################
use strict;
use encoding "utf-8";
use Cos::w2 qw($dbh);
use Cos::std;
use Text::CSV;

print "Content-type: text/plain\n\n";

Cos::w2::authenticate();

my %FORM   = Cos::w2::get_input();
my $lab = $FORM{'lab'};

my %Labs;

# Successive calls to get_labs adds keys and values to the %Labs hash
# The keys are lab_id's and the values are the bitwise ORing of 0x01 | 0x02 | 0x04
# to indicate which table the lab_id came from (for diagnistic purposes used by other subroutines)
&get_labs("SELECT DISTINCT lab_id FROM lab_info", 0x01);
&get_labs("SELECT DISTINCT lab_id FROM retailer", 0x02);
&get_labs("SELECT DISTINCT U_InfoId FROM Users WHERE U_Type = 'L'", 0x04);

my($acct);

my($Username, $AcctName, $OrgName, $LabName, $Count, $Mbox, $Error);
my($Uid, $Transport);

# $Username comes from the Users table
# $AcctName comes from the Users table
# $LabName comes from the lab_info table
# $Count is the number of retailer table records for a lab (includes inactive)

my($CSV)      = Text::CSV->new( { binary => 1 });

# Lab
# Count
# Username
# Business Name
# Parent Business Name
# Acc'ts
# Mbox
# Problems

my($Reccnt) = 0;

print '#+,Lab,Username,Labname,Acctname,Transport,Count,Mbox,Error',"\n";
foreach $lab (sort { $a <=> $b } keys %Labs) {
	$Count = 0;
	&get_user_count($lab);		# assigns a value to $Count
	&get_lab_info($lab);		# assigns $LabName=lab_info.bizname and $Mbox=lab_info.mbox
	&get_users($lab);		# assigns $Username=Users.U_Username;$AcctName=Users.U_ParentName

	++$Reccnt;
	$CSV->combine(
		$Reccnt,
		$lab,
		$Username,
		$LabName,
		$AcctName,
		$Transport,
		$Count,
		$Mbox,
		$Error
	);
        print ascii($CSV->string()), "\n";
}
print "#=,$Reccnt\n";


###########################################################
#
#	subroutine name:  get_labs
#	purpose:  get a complete list of labs and indicate which table the information came from
#
###########################################################

sub get_labs {
	my($query, $mode) = @_;

	my $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute                    or die "Can't execute: $query. Reason: $!";

	while( (($lab) = $sth->fetchrow_array()) ) {
		$Labs{$lab} |= $mode;
	}
	$sth->finish;
}


###########################################################
#
#	subroutine name:  get_user_count
#	purpose:  how many retailers does this lab have signed up for F, R, or W
#
###########################################################

sub get_user_count {
	my($lab) = @_;
	my($query) = "SELECT COUNT(*) FROM retailer WHERE lab_id = ?";

	my $sth = $dbh->prepare($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($lab)             or die "Can't execute: $query. Reason: $!";

	($Count) = $sth->fetchrow_array();
	$Count ||= '-';

	$Error = '';
	$sth->finish;
}


###########################################################
#
#	subroutine name:  get_lab_info
#	purpose:  get information from the lab_info table
#
###########################################################

sub get_lab_info {
	my($lab) = @_;
	my($query) = "SELECT * FROM lab_info WHERE lab_id = ?";
	my($bogus) = 0;

	my $sth = $dbh->prepare($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($lab)             or die "Can't execute: $query. Reason: $!";

	my($ref) = $sth->fetchrow_hashref();
	unless (defined $ref) {
		$LabName = '';
		$Mbox    = '';
		$Error  .= 'No lab_info record ';
		return;
	}
	$LabName = $ref->{bizname};
	$Mbox    = $ref->{mbox};
	$Transport = $ref->{transport};

	while ($sth->fetchrow_hashref()) {
		++$bogus;
	}
	if ($bogus) {
		$Error .= "Dup lab_info record($bogus) ";
	}
	$sth->finish;
}


###########################################################
#
#	subroutine name:  get_users
#	purpose:  get information from the Users table
#
###########################################################

sub get_users {
	my($lab) = @_;
	my($query) = "SELECT * FROM Users WHERE U_Type = 'L' AND U_InfoId = ?";
	my($bogus) = 0;

	my $sth = $dbh->prepare($query) or die "Can't prepare: $query. Reason: $!";
	$sth->execute($lab)             or die "Can't execute: $query. Reason: $!";

	my($ref) = $sth->fetchrow_hashref();
	unless (defined $ref) {
		$Uid      = '';
		$Username = '';
		$AcctName = '';
		$Error   .= 'No Users record';
		return;
	}
	$Uid      = $ref->{U_UserId};
	$Username = $ref->{U_Username};
	$AcctName = $ref->{U_ParentName};

	while ($sth->fetchrow_hashref()) {
		++$bogus;
	}
	if ($bogus) {
		$Error .= "Dup Users record($bogus) ";
	}
	$sth->finish;
}
