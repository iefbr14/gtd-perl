# $Id: Order.pm,v 1.3 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::Order;

=head1 OPTIONAL

 $ref = fetch($order_id);
 $sth = select_new();

=head1 DESCRIPTION

=item fetch

Used to return a hashref to the order

=item select_new

Used to return a DBI statement handle to those orders that are new.

=cut

package Cos::Order;

use strict;
#use warnings;

use DBI;
use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	#our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw(&fetch &select_new);
}
#our @EXPORT_OK;
use vars @EXPORT_OK;

my($Map);

sub fetch {
	my($query) = <<'EOF';
SELECT *
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(promised_date,'%m%d%y') as datePromised
,DATE_FORMAT(promised_date,'%h:%i%p') as timePromised
FROM orders_pending 
WHERE orders_pending_id = ?
EOF

	my($sth, $ref);
	my($dbh) = Cos::Dbh::new();

        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute(@_)             or die "Can't execute: $query. Reason: $!";

	$ref = $sth->fetchrow_hashref();
	$sth->finish();

	return $ref;
}

sub select_new {
	my($class) = @_;
	$class = 'M' unless $class;

	my($query) = <<'EOF';
SELECT *
,DATE_FORMAT(created_date,'%m%d%y') as dateOrdered
,DATE_FORMAT(created_date,'%m%d%y') as datePromised
,DATE_FORMAT(created_date,'%h:%i%p') as timePromised
FROM orders_pending 
WHERE status=? 
ORDER BY orders_pending_id
EOF

	my($sth, $ref);
	my($dbh) = Cos::Dbh::new();

        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute($class)         or die "Can't execute: $query. Reason: $!";

	return $sth;
}

1;
