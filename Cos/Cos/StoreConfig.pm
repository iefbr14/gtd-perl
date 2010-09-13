# $Id: StoreConfig.pm,v 1.4 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::StoreConfig;

=head1 DESCRIPTION

Obsolete please don't use.

=cut

package Cos::StoreConfig;

use strict;
#use warnings;

use DBI;
use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(&getStoreId &getStoreName);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw($Var1 %Hashit &func3);
}
use vars @EXPORT_OK;

#  <P>this class retreives from a file and stores the information that is
#  used to convert store numbers as prvided in the pick-ticket requests
#  into store numbers that are used by the lab along with providing store
#  name and other informaiton.
#  
#  <P>The store file format is:
#  <PRE>raw store number ":" lab store number ":" store name ":" optional comment</PRE></P>
#  
#  <P>for example:
#  <PRE> 1:234:bob's house of vision: he dont pay fast
#  2:2299: joex fine glasses: he is out best customer<\PRE>
# </P>
#

my %Store;

my $Store;	# magic info that comes from the mime information.
my $Lab;
my $Name;

sub StoreConfig {
	my($configFile) = @_;

	my($raw_store, $lab, $name, $comment);

	open(F, $configFile) or die "Can't open $configFile ($!)\n";
	while (<F>) {
		next if /^\s*$/;
		next if /^\s*#/;

		chomp;

		($raw_store, $lab, $name, $comment) = split(':');

		$Store{$raw_store} = {
			id      => $lab,
			name    => $name,
			comment => $comment || '',
		}
	}
	close(F);
}

sub getStoreId {
	my($raw_store) = @_;

	get_remeber($raw_store);

	return '!NONE!' unless defined $Store{$raw_store};

	return $Store{$raw_store}{id};
}

sub getStoreLab {
	my($raw_store) = @_;

	get_remeber($raw_store);

	return $Store{$raw_store}{lab};
}

sub getStoreName {
	my($raw_store) = @_;

	get_remeber($raw_store);

	return "Store: $raw_store" unless defined $Store{$raw_store};

	return $Store{$raw_store}{name};
}

sub getStoreComment {
	my($raw_store) = @_;

	# comments only existed in the txt version of store mapping
	# file.  They don't exist in the database.
	# We don't use them and we don't care about them.

	return '' unless defined $Store{$raw_store};

	return $Store{$raw_store}{comment} || '';
}

sub get_remeber {
	my($raw_store) = @_;

	return if defined $Store{$raw_store};

	get_lab_mapping($raw_store);
}


sub get_lab_mapping {
	my($cust) = @_;
	my($dbh) = Cos::Dbh::new();
	my($ref);

	my($sth) = $dbh->prepare(<<"EOF");
select * from user_info where user_id = ?
EOF
	
	$sth->execute($cust);
	if ($ref = $sth->fetchrow_hashref()) {
		$Store{$cust}{lab} = $ref->{lab_id};
		$Store{$cust}{id} = $cust;
		$Store{$cust}{name} = $ref->{name};
		return;
	}
}

sub put_lab_mapping {
	my($user_id) = @_;
	my($dbh) = Cos::Dbh::new();
	my($ref);

	my($sth) = $dbh->prepare(<<"EOF");
insert into lab_customer_id(user_id,lab_id,cusomer_id,lab_number)
values (?,?,?,?)
EOF
	
	$sth->execute($user_id);
	while ($ref = $sth->fetchrow_hashref()) {
#		print join(' ', %$ref), "\n";
		print "Processing: $ref->{name}\n";

		storeIdRemember($ref->{user_id});
	}
	return $ref;
}
1;
