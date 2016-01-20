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

import "gtd/meta"
import "gtd/option"
import "gtd/display"

//-- List high priority next actions
func Report_todo(args []string) int {
	limit := option.Int("Limit", 10)

	meta.Filter("+active", "^priority", "priority")

	var title string
	if len(args) == 0 {
		title = "ToDo Tasks"
	} else {
		title = meta.Desc(args)
	}

	display.Header(title)

	count := 0
	for _, t := range meta.Sorted() {
		if !t.Is_task() { // only actions
			continue
		}

		display.Task(t, "")

		if count++; count >= limit {
			break
		}
	}
	return 0
}
