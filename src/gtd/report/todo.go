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

import "gtd/task";
import "gtd/meta";
import "gtd/option";
import "gtd/task";

//-- List high priority next actions
func Report_todo(args []string) {
	my($limit) = option("Limit", 10);

	gtd.Meta_filter("+active", '^priority', "priority");
	my($title) = meta.Desc(args)(@_) || "ToDo Tasks";

	report_header($title);

	my($count) = 0;
	for my $ref (gtd.Meta_sorted("^pri")) {
		next unless $ref->is_task();	// only actions
//#FILTER	next if $ref->filtered();		// other filterings

		display_task($ref);

		last if ++$count >= $limit;
	}
}
