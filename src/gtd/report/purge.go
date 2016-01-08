package report

/*
NAME:

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

*/

use Hier::Util;
use Hier::Walk;
use Hier::Meta;

//-- interactive purge completed work
func Report_purge(args []string) {
	gtd.Meta_filter("+dead", '^tid', "simple");

	my($criteria) = gtd.Meta_desc(@_);

	my($walk) = new Hier::Walk(
		done   => \&end_detail,
	);

	panic("Criteria $criteria ignore for purge (re-write purge)\n");
	$walk->walk('m');
}

// purge deletes on walk back up.
sub end_detail {
	my($ref) = @_;

	my($done) = $ref->get_completed();

	return unless $done;

	my($tid) = $ref->get_tid();
	my($title) = $ref->get_tid();

	print "delete $tid\t# $done -- $title\n";
}
