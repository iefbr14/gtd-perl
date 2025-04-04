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
import "gtd/display"

//-- quick List by various methods
func Report_task(args []string) int {
	meta.Filter("+g:live", "^title", "task") // Tasks filtered by goals

	list := meta.Pick(args)
	if len(list) == 0 {
		list = meta.Pick([]string{"actions"})
	}

	title := meta.Desc(args)
	display.Header("Tasks -- " + title)

	for _, ref := range list {
		display.Task(ref, "")
	}
	return 0
}
