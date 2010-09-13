# $Id: JobSave.pm,v 1.5 2003/12/31 14:39:19 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::JobSave;

 $id = function(arg);

=head1 DESCRIPTION

Needs to be written

=cut


package Cos::JobSave;

use strict;
#use warnings;

use Cos::Dbh;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

my($Map);

sub save {
	my($job) = @_;

	return do_work($job, 1);
}

sub dump {
	my($job) = @_;

	do_work($job, 0);
}

sub do_work {
	my($job,$do_save) = @_;
	my($key, $val, $map, @name, @vals, $sql);
	my($sth);

$| = 1;

	&load_mapping() unless $Map;

	@name = ( 'created_by');
	@vals = ( 'cos-mail');

	foreach $key (sort keys %$Map) {
		next if $key eq 'created_by';

		$map = $Map->{$key} || '';

		if ($map && defined $job->{$map}) {
			$val = $job->{$map};
		} else {
			$val = '';
		}

		push(@name, $key);
		push(@vals, $val);

		if ($key eq 'trace_file_data') {
			$val = '*** Binary ***' if $val ne '';
		}
		#printf "%-25s %-20s %s\n", $key, $map, $val;
	}

	return undef unless $do_save;

	my($dbh) = Cos::Dbh::new();

	$sql = 'insert into orders_pending ( '
		. join(',', @name)
		. ' ) values ( ?'
		. ',?' x (scalar(@name)-1) . ')';
#print "$sql\n";
	$sth = $dbh->prepare($sql);
	$sth->execute(@vals);

	#=============================================
	# get the order id we just inserted.
	#=============================================

	my($query) = "select last_insert_id()";
        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute()               or die "Can't execute: $query. Reason: $!";

	my($ref) = $sth->fetchrow_hashref();
	my($order) = $ref->{'last_insert_id()'};

	print "order: $order\n";

	return $order;
}

sub load_mapping {
	my($to, $from);

	open(F, "< /home/cos/etc/mapping.tbl") or die;

	while (<F>) {
		next if /^\s*#/;
		next if /^\s*$/;

		chomp;
		($to, $from) = split(' ');

		$Map->{$to} = $from;
	}
}

1;
