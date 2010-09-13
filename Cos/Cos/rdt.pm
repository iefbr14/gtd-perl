#!/usr/bin/perl -w

=head1 NAME

 use Cos::rdt

=head1 SYNOPIS

used to generate rdt files

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT

=head1 SEE ALSO

=cut

package Cos::rdt;

use strict;
#use warnings;

use Getopt::Std;
use DBI;
use Cos::Constants;
use Cos::Values;
use Cos::Dbh;

BEGIN {
        use Exporter   ();
        use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

        # set the version for version checking
        $VERSION     = 1.00;
        # if using RCS/CVS, this may be preferred
        $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

        @ISA         = qw(Exporter);
        @EXPORT      = qw(generate_rdt);
        %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

        # your exported package globals go here,
        # as well as any optionally exported functions
        @EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

require "Cos/rfile.pl";
require "Cos/dfile.pl";

sub generate_rdt {
	my($dir, $aOrder) = @_;

	my $order  = $aOrder->{orders_pending_id};
        my $userId = $aOrder->{user_id};
        my $labId  = $aOrder->{lab_id};
	my $seqNum = lpad($aOrder->{seq_num}, 3);
	
	my($date) = $aOrder->{created_date};
	$date =~ s/[^\d]//g;
	# YYYYmmdd...
	# 0   4 6
        my $year   = substr($date, 0, 2);
        my $month  = substr($date, 4, 2);
        my $day    = substr($date, 6, 2);

	# Find the customer_id for this webrx user at the specified lab
	#
	my($customerId) = lpad(getcust_id($labId, $userId), 3);

        print "Processing Order # $order, lab: $labId, user: $userId, cust: $customerId\n";

	# insert store number into order
	$aOrder->{customer_id} = $customerId;
	$aOrder->{seqNum} = $seqNum;

	my($base) = FileName($dir, $labId, $userId, $customerId, $day, $month, $seqNum);

	Set_Order($aOrder);

	r_write($base . 'r', $aOrder);
	d_write($base . 'd', $aOrder);
	t_write($base . 't', $aOrder);

	return $base;
}

sub FileName {
	my($dir, $lab_id, $user_id, $store, $day, $mon, $seq) = @_;
	my(@Month) = ('0','1','2','3','4','5','6','7','8','9','a','b','c');
	
	my(@DayOfMonth) = (
		'0','1','2','3','4','5','6','7','8','9','a','b','c',
		'd','e','f','g','h','i','j','k','l','m','n','o','p',
		'q','r','s','t','u','v');

	return  $dir
		. $lab_id . '-' . $user_id . ':'
		. lpad('1',2) 
		. lpad($store,3)
		. $Month[$mon] 		# month 1-12
		. $DayOfMonth[$day] 	# day   1-31
		. substr($seq,0,1) 
		. "." 
		. substr($seq,1,3);
}

sub lpad {
	my($v, $pad) = @_;

	return sprintf("%0${pad}d", $v);
}

#===============================================================================
# Save trace file.
#===============================================================================
sub t_write {
	my($file, $aOrder) = @_;
	my($trace) = $aOrder->{trace_file_data};

	if (!defined($trace) || length($trace) == 0) {
		print "No trace file.\n";
		return;
	}
	open(F, "> $file\0") or die "Can't create trace-file $file ($!)\n";
	print F $trace;
	close(F);
	print "Trace file: $file\n";
}


#===============================================================================
# Get the customer-id
#===============================================================================
sub getcust_id {
	my($lab, $user) = @_;

	my($query) = <<'EOF';
SELECT store_id
FROM retailer
WHERE user_id = ?
EOF

	my($sth, $ref);

	my($dbh) = Cos::Dbh::new();
        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute($user)          or die "Can't execute: $query. Reason: $!";

	while ($ref = $sth->fetchrow_hashref()) {
		$sth->finish();
		return $ref->{store_id}
	}
	$sth->finish();
	die "Can't find customer_id for $lab, $user\n";
}

