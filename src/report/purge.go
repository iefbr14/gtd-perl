package report

=head1 NAME

=head1 USAGE

=head1 REQUIRED ARGUMENTS

=head1 OPTION

=head1 DESCRIPTION

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE and COPYRIGHT

(C) Drew Sullivan 2015 -- LGPL 3.0 or latter

=head1 HISTORY

=cut

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_purge);
}

use Hier::Util;
use Hier::Walk;
use Hier::Meta;

my %Depth = (
	'value'   => 1,
	'vision'  => 2,
	'role'    => 3,
	'goal'    => 4,
	'project' => 5,
	'action'  => 6,
);

sub Report_purge {	#-- interactive purge completed work
	meta_filter('+dead', '^tid', 'simple');

	my($criteria) = meta_desc(@_);

	my($walk) = new Hier::Walk(
		done   => \&end_detail,
	);

	die "Criteria $criteria ignore for purge (re-write purge)\n";
	$walk->walk('m');
}

# purge deletes on walk back up.
sub end_detail {
	my($ref) = @_;

	my($done) = $ref->get_completed();

	return unless $done;

	my($tid) = $ref->get_tid();
	my($title) = $ref->get_tid();

	print "delete $tid\t# $done -- $title\n";
}

1;  # don't forget to return a true value from the file
