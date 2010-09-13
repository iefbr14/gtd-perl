# $Id: Dbh.pm,v 1.10 2006/04/13 18:12:46 cos Exp $
# $Source $
#
=head1 USAGE

 use Cos::Dbh;

 my($dbh) = new Cos::Dbh;

 $ref = sql("select * from table where key = ?", $key)

=head1 DESCRIPTION

Used to connect to the Cos database.

=item sql

Used to make a one item query and return a hashref to the result

=cut

package Cos::Dbh;

use strict;
#use warnings;

# If we are not using Mod_Perl
#    if (!$ENV{'MOD_PERL'}) {
#        
#	require DBI;	# then we need to require the DBI package
#    }

use DBI;

BEGIN {
	use Exporter   ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	# if using RCS/CVS, this may be preferred
	$VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

	@ISA         = qw(Exporter);
	@EXPORT      = qw(sql);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

	# your exported package globals go here,
	# as well as any optionally exported functions
	@EXPORT_OK   = qw();
}
use vars @EXPORT_OK;

my($Dbh);

#my($Host) = 'localhost';
#my($Host) = 'drugs.int.iplink.net';
my($Host) = 'cosdb.optical-online.com';

sub host {
	if (@_) {
		my($host) = @_;

		undef $Dbh;
		$Host = $host;
	}
	return $Host
}

#
# return a Dbh handle (will be cached)
#
sub new {
	return $Dbh if defined $Dbh;

	my($package) = @_;

	if (scalar(@_) > 0 && $_[0] eq 'Cos::Dbh') {
		shift @_;
	}

	if (@_) {
		my(%opt) = @_;

		if (defined $opt{host} && $opt{host}) {
			$Host = $opt{host};
		}
	}

	if ($ENV{'COS_HOST'}) {
		$Host = $ENV{'COS_HOST'};
		print "Switch host to $Host\n";
	}
			
	$Dbh = DBI->connect("DBI:mysql:webrx:$Host", "WEB", "");

	die "Can't connect to database\n" unless defined $Dbh;
	return $Dbh;
}

#
# return a hash ref to an sql query.
# extra args are passed to the execute.
#
sub sql {
        my($query) = shift @_;

	my($sth);
	my($dbh) = new();

        $sth = $dbh->prepare ($query) or die "Can't prepare: $query. Reason: $!";
        $sth->execute(@_)             or die "Can't execute: $query. Reason: $!";


	my($ref);
	if ($query =~ /^\s*select/i) {
		$ref = $sth->fetchrow_hashref();
	} else {
		$ref = { 'rows' => $sth->rows() };
	}

	$sth->finish;

	return $ref;
}

1;
