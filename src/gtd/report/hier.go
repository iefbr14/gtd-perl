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
import "gtd/color"
import "gtd/task"
import "gtd/display"

//-- Hiericial List of Values/Visions/Roles...
func Report_hier(args []string) int {
	meta.Filter("+active", "^title", "hier")

	w := meta.Walk(args)
	w.Detail = hier_detail
	w.Filter()
	w.Walk()

	return 0
}

func hier_detail(w *task.Walk, t *task.Task) {
	color.Ref(t)
	display.Task(t, "")
}
