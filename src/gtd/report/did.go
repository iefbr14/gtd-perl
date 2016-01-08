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


use Hier::Option;
use Hier::Meta;

//-- update listed projects/actions doit date to today
func Report_did(args []string) {
	for my $tid (@_) {
		my $ref = gtd.Meta_find($tid);

		unless (defined $ref) {
			print "Task $tid not found to tag done\n";
			next;
		}
		$ref->set_doit(get_today());
		$ref->update();
	}
}
