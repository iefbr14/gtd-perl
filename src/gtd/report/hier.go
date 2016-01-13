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

//? my $Mask = 0

//-- Hiericial List of Values/Visions/Roles...
func Report_hier(args []string) int {
	meta.Filter("+active", "^title", "hier")

/*?

	$Mask  = option("Mask")

	my(@top)
	my($depth) = ''
	for _, criteria := range meta.Argv(args) {
		if ($criteria =~ /^\d+$/) {
			push(@top, $criteria)
		} else {
			my($type) = type_val($criteria)
			if ($type) {
				$depth = $type
			} else {
				panic("unknown type $criteria\n")
			}
		}
	}
	if (@top == 0) {
		my $parent = option("Current")
		if ($parent) {
			@top = ( $parent )
		} else {
			@top = ( 'm' )
		}
	}

	for my $top (@top) {
		my($walk) = new Hier::Walk(
			detail => \&hier_detail,
			done   => \&end_detail,
		)
		$walk->filter()
		$walk->set_depth(map_depth($top, $depth))

		$walk->walk($top)
	}
?*/
	return 0
}

/*?
sub map_depth {
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
}
?*/

func hier_detail(w *task.Walk, t *task.Task) {
	color.Ref(t)
	display.Task(t, "")
}


func end_detail(w *task.Walk, t *task.Task) {
}
