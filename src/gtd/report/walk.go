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


import "gtd/meta";
import "gtd/option";
import "gtd/task";

//-- Command line walk of a hier
func Report_noop(args []string) {
	if len(args) == 0 {
		fmt.Println("NO task specified to walk");
		return;
	}

	dir := walk_down
	action := walk_noop

	gtd.Meta_filter("+all", '^tid', "simple");

	for task := range args {
		if ($task eq "set") {
			action = walk_set;
			continue
		}

		if ($task eq "active") {
			action = walk_active;
			continue
		}
		if ($task eq "someday") {
			action = walk_someday;
			continue
		}

		if ($task eq "doit"  or $task eq "task") {
			display_mode("doit");
			continue
		}
		if ($task eq "wiki") {
			display_mode("wiki");
			continue
		}
		if ($task eq "list") {
			display_mode("list");
			continue
		}

		if ($task eq "tid") {
			display_mode("tid");
			continue
		}

		if ($task eq "up") {
			$dir = \&up;
			continue
		}
		if ($task eq "down") {
			$dir = \&down;
			continue
		}

		if ($task !~ /^\d+$/) {
			panic("Unknown command: $task\n");
		}

		my $ref = meta.Find($task);
		unless (defined $ref) {
			panic("Task $task not found to walk\n");
			//return;
		}

		// apply all actions to task in direction specified
		ref.Set_level(1);
		dir(ref, action);
	}
}

sub set {
	my($ref) = @_;

	my $val;

	if ($val = option("Category")) {
		$ref->set_category($val);
	}

	if ($val = option("Context")) {
		$ref->set_context($val);
	}

	if ($val = option("Timeframe")) {
		$ref->set_timeframe($val);
	}

	if ($val = option("Note")) {
		$ref->set_note($val);
	}

	if ($val = option("Priority")) {
		$ref->set_priority($val);
	}

	if ($val = option("Complete")) {
		$ref->set_priority($val);
	}

	if ($val = option("Task")) {
		$ref->set_description($val);
	}

	$ref->update();
}

sub walk_down(ref *Task, action func(* task.Task)) {
	ref.Display();

	foreach my $cref (sort_tasks $ref->get_children()) {
		down($cref, $action);
	}

	action(ref);
}

sub walk_up(ref *Task, action func(* task.Task)) {
	my($ref, $action) = @_;

	foreach my $cref (sort_tasks $ref->get_parents()) {
		up($cref, $action);
	}
	ref.Display();

	action(ref);
}

sub walk_noop(ref *Task) {
	my($ref) = @_;
}

sub walk_someday(ref *Task) {
	my($ref) = @_;

	$ref->set_isSomeday('y');
}

func walk_active(ref *Task) {
	ref.IsSomeday = false
}
