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

	var top task.Tasks
//?	depth := 0
	for _, criteria := range meta.Argv(args) {
		if task.IsTask(criteria) {
			top = append(top, task.Lookup(criteria))
		} else {
			panic("... code Report_hier type search");
//?			my($type) = type_val($criteria)
//?			if ($type) {
//?				$depth = $type
//?			} else {
//?				panic("unknown type " + criteria)
//?			}
		}
	}

	if len(top) == 0 {
		top = meta.Current()
		if len(top) == 0 {
			top = meta.Matching_type('m');
		}
	}

//?	for _, t := range top {
		w := task.NewWalk()
		w.Detail = hier_detail

//?		w.Filter()
//?		w.Depth = map_depth(top) // $walk->set_depth(map_depth($top, $depth))

		w.Walk(top)
//?	}
	return 0
}

func map_depth(ref *task.Task) byte {
	return 'm'
/*?
	my($ref, $depth) = @_

	return $depth if $depth

	my($type) = 'm'

	// not a reference to a task
	if (!ref $ref) {
		// is it a tid?
		if ($ref =~ /^\d+$/) {
			$ref = Hier::Tasks::find($ref)
			$type = $ref->get_type()
		} else {
			// use the type that was pass
			$type = $ref
		}
	}

	return 'a" if $type eq "p'
	return 'p" if $type eq "g'
	return 'g" if $type eq "o'; # o == ROLE
	return 'o'
?*/
}

func hier_detail(w *task.Walk, t *task.Task) {
	color.Ref(t)
	display.Task(t, "")
}
