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

//? my %Ancestors

//-- take listed actions/projects
func Report_take(args []string) int {
	meta.Filter("+all", "^tid", "none")

	//?	my($key, $val, $changed)

	ancestors := map[int]bool{}

	parents := meta.Current()
	if len(parents) == 0 {
		fmt.Printf("No parent for take\n")
		return 1
	}

	list := meta.Pick(args)
	if len(list) == 0 {
		fmt.Printf("No items to take\n")
		return 1
	}

	for _, parent := range parents {
		get_ancestors(ancestors, parent)
		for _, child := range list {

			tid := is_ancestor(ancestors, child)
			if tid != 0 {
				fmt.Printf("Child %d shares ancestor for %s\n",
					tid, parent.Tid)
				return 1
			}
			fmt.Printf("Take %d <= %d\n", parent, child.Tid)
		}
	}
	return 0
}

func get_ancestors(ancestors map[int]bool, t *task.Task) {
	tid := t.Tid

	ancestors[tid] = true

	for _, parent := range t.Parents {
		get_ancestors(ancestors, parent)
	}
}

func is_ancestor(ancestors map[int]bool, t *task.Task) int {

	tid := t.Tid
	if _, ok := ancestors[tid]; ok {
		return tid
	}

	ancestors[tid] = true
	for _, child := range t.Children {
		// check my children recursivly as well
		tid = is_ancestor(ancestors, child)
		if tid > 0 {
			return tid // yup.
		}
		// not this one, continue looking
	}

	// nope no child is an ancestor
	return 0
}
