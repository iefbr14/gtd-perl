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
import "gtd/task"

//-- Command line walk of a hier
func Report_walk(args []string) {
	meta.Filter("+all", "^tid", "simple")

	/*?
		if len(args) == 0 {
			fmt.Println("NO task specified to walk")
			return
		}

		dir := walk_down
		action := walk_noop


		for task := range args {
			if ($task == "set") {
				action = walk_set
				continue
			}

			if ($task == "active") {
				action = walk_active
				continue
			}
			if ($task == "someday") {
				action = walk_someday
				continue
			}

			if ($task == "doit"  or $task eq "task") {
				display_mode("doit")
				continue
			}
			if ($task == "wiki") {
				display_mode("wiki")
				continue
			}
			if ($task == "list") {
				display_mode("list")
				continue
			}

			if ($task == "tid") {
				display_mode("tid")
				continue
			}

			if ($task == "up") {
				$dir = \&up
				continue
			}
			if ($task == "down") {
				$dir = \&down
				continue
			}

			if ($task !~ /^\d+$/) {
				panic("Unknown command: $task\n")
			}

			t := meta.Find($task)
			unless (defined $ref) {
				panic("Task $task not found to walk\n")
				//return
			}

			// apply all actions to task in direction specified
			ref.Set_level(1)
			dir(ref, action)
		}
	?*/
}

func set() { /*?
		my($ref) = @_

		my $val

		if ($val = option("Category")) {
			t.Set_category($val)
		}

		if ($val = option("Context")) {
			t.Set_context($val)
		}

		if ($val = option("Timeframe")) {
			t.Set_timeframe($val)
		}

		if ($val = option("Note")) {
			t.Set_note($val)
		}

		if ($val = option("Priority")) {
			t.Set_priority($val)
		}

		if ($val = option("Complete")) {
			t.Set_priority($val)
		}

		if ($val = option("Task")) {
			t.Set_description($val)
		}

		$ref->update()
	?*/
}

func walk_down(ref *Task, action func(*task.Task)) { /*?
		display.Task(ref)

		for my $cref (sort_tasks t.Children()) {
			down($cref, $action)
		}

		action(ref)
	?*/
}

func walk_up(ref *Task, action func(*task.Task)) { /*?
		my($ref, $action) = @_

		for my $cref (sort_tasks t.Parents()) {
			up($cref, $action)
		}
		display.Task(ref)

		action(ref)
	?*/
}

func walk_noop(ref *Task) { /*?
		my($ref) = @_
	?*/
}

func walk_someday(ref *Task) { /*?
		my($ref) = @_

		t.Set_isSomeday('y')
	?*/
}

func walk_active(t *task.Task) {
	t.Set_IsSomeday(false)
}
