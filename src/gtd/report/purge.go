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

import "fmt"

import "gtd/task"
import "gtd/meta"

//-- interactive purge completed work
func Report_purge(args []string) int {
	meta.Filter("+dead", "^tid", "simple")

	w := meta.Walk(args)
	w.Done = purge_detail

	panic("Criteria $criteria ignore for purge (re-write purge)\n")
	w.Walk()
	return 0
}

// purge deletes on walk back up.
func purge_detail(w *task.Walk, t *task.Task) {
	done := t.Completed

	if done == "" {
		return 
	}

	fmt.Printf("delete %d\t# %s -- %s\n", t.Tid, done, t.Title)
}
