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
import "gtd/option"
import "gtd/task"
import "gtd/display"

//-- Command line walk of a hier
func Report_walk(args []string) int {
	meta.Filter("+all", "^tid", "simple")

	if len(args) == 0 {
		fmt.Println("NO task specified to walk")
		return 1
	}

	var action func(*task.Task)

	dir := walk_down
	action = walk_noop

	for _, cmd := range meta.Argv(args) {
		// rdebug("cmd: %s\n", cmd)
		if cmd == "set" {
			action = walk_set
			continue
		}

		if cmd == "active" {
			action = walk_active
			continue
		}
		if cmd == "someday" {
			action = walk_someday
			continue
		}

		if cmd == "doit" || cmd == "task" {
			display.Mode("doit")
			continue
		}
		if cmd == "wiki" {
			display.Mode("wiki")
			continue
		}
		if cmd == "list" {
			display.Mode("list")
			continue
		}

		if cmd == "tid" {
			display.Mode("tid")
			continue
		}

		if cmd == "up" {
			dir = walk_up
			continue
		}
		if cmd == "down" {
			dir = walk_down
			continue
		}

		if !task.MatchId(cmd) {
			fmt.Printf("Unknown command: %s\n", cmd)
			continue
		}

		t := meta.Find(cmd)
		if t == nil {
			return 1
		}

		// apply all actions to task in direction specified
		t.Set_level(1)
		dir(t, action)
	}
	return 0
}

func walk_set(t *task.Task) {
	if val := option.Get("Category", ""); val != "" {
		t.Set_category(val)
	}

	if val := option.Get("Context", ""); val != "" {
		t.Set_context(val)
	}

	if val := option.Get("Timeframe", ""); val != "" {
		t.Set_timeframe(val)
	}

	if val := option.Get("Note", ""); val != "" {
		t.Set_note(val)
	}

	if val := option.Get("Priority", ""); val != "" {
		t.Set_KEY("priority", val)
	}

	if val := option.Get("Complete", ""); val != "" {
		t.Set_KEY("complete", val)
	}

	if val := option.Get("Task", ""); val != "" {
		t.Set_description(val)
	}

	t.Update()
}

func walk_down(t *task.Task, action func(*task.Task)) {
	// rdebug("down: %v\n", t)

	display.Task(t, "")

	for _, cref := range t.Children {
		walk_down(cref, action)
	}

	action(t)
}

func walk_up(t *task.Task, action func(*task.Task)) {
	// rdebug("up: %v\n", t)

	for _, cref := range t.Parents {
		walk_up(cref, action)
	}
	display.Task(t, "")

	action(t)
}

func walk_noop(t *task.Task) {
}

func walk_someday(t *task.Task) {
	t.Set_isSomeday("y")
}

func walk_active(t *task.Task) {
	t.Set_isSomeday("n")
}
