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

import "gtd/meta"
import "gtd/task"

//-- Delete listed actions/projects (will orphine items)
func Report_delete(args []string) int {
	ok := true
	for _, ref := range meta.Pick(args) {
		for _, child := range ref.Children {
			fmt.Printf("Delete %d first\n", child.Tid)
			ok = false
			continue
		}

		tid := ref.Tid
		ref.Delete()
		fmt.Printf("Task %s deleted\n", tid)
	}
	if ok {
		return 0
	}
	return 1
}

func delete_hier(tasks []*task.Task) {
	for _, ref := range tasks {
		delete_hier(ref.Children)

		ref.Delete()
	}
}
