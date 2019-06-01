package GTD::Report::purge;

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

use GTD::Util;
use GTD::Walk;
use GTD::Meta;

sub Report_purge {	#-- interactive purge completed work
	meta_filter('+all', '^tid', 'simple');

	my($criteria) = meta_desc(@_);

	my($walk) = new GTD::Walk(
		done   => \&end_detail,
	);

	###BUG### Re-write purge
	# add options to check for age of done.
	#     default to 1 month for youngets (doit?)
	# walk down all
	# if has all done children 
	#	-- note if note done.
	#	--      else ask if delete -R
	# 
	die "Purge needs rewrite.\n";
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
