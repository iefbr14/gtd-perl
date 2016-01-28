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
import "strings"

import "gtd/color"
import "gtd/meta"
import "gtd/task"
import "gtd/display"

type ListSet struct {
	list []*task.Task
}

//-- report kanban of projects/actions
func Report_kanban(args []string) int {

	// counts use it and it give a context
	meta.Filter("+active", "^tid", "simple")

	nargs := []string{}
	for _, arg := range meta.Argv(args) {
		if arg[0] == '.' {
			kanban_bump(arg)
			continue
		}
		/*?
		if ($arg =~ m/^(\d+)=(.)$/) {
			kanban_state($1, $2)
			next
		}
		*/
		nargs = append(nargs, arg)
	}

	// done if we had args but all were processed
	if len(args) > 0 && len(nargs) == 0 {
		return 0
	}

	list := meta.Pick(nargs)

	if len(list) == 0 {
		nargs = append(nargs, "roles")
		list = meta.Pick(nargs)
	}
	check_roles(list)
	return 0
}

func kanban_bump(arg string) {
	fail := 0
	list := []*task.Task{}

	for _, task_id := range strings.Split(arg, ",") {
		t := meta.Find(task_id)
		if t == nil {
			fail++
			continue
		}
		list = append(list, t)
		continue
	}
	if fail > 0 {
		panic("Nothing bunped due to errors\n")
	}

	for _, t := range list {
		new := t.Bump()

		if new != 0 {
			name := task.StateName(new)

			display.Task(t, "| now <<< "+name+" >>>")
		} else {
			state := string(t.State)

			display.Task(t, "|<<< unknown state "+state)
		}
	}
}

func kanban_state(task_id string, state string) {

	t := meta.Find(task_id)

	if t == nil {
		return
	}

	t.Set_state(state[0])
}

func check_hier() {
	count := 0

	// find all hier records
	for _, t := range meta.All() {
		if !t.Is_hier() {
			continue
		}
		if t.Filtered() {
			continue
		}

		if t.State == 'z' {
			if t.Completed == "" {
				if count == 0 {
					fmt.Printf("To tag as done:\n")
				}
				display.Task(t, "(tag as done)")
				count++
			}
		}
	}
}

func check_roles(tasks task.Tasks) {
	for _, t := range tasks {
		display.Rgpa(t, "")
		kanban_check_role(t)
	}
}

func kanban_check_role(role_ref *task.Task) {
	var anal, devel, ick, test, wiki, repo ListSet

	for _, gref := range role_ref.Children {
		for _, t := range gref.Children {
			state := t.State

			// unless ($state =~ m/[-abcdfitrwz]/) {
			//	display.Task(t, "Unknown state $state")
			//	next
			// }

			if state != '-' {
				check_title(t)
			}

			check_state(t, 'b', &anal)
			check_state(t, 'd', &devel)
			check_state(t, 'i', &ick)
			check_state(t, 'r', &repo)
			check_state(t, 't', &test)
			check_state(t, 'u', &wiki)
		}
	}

	needs := ""
	if len(anal.list) > 0 {
		needs += " analysys"
	}
	if len(devel.list) > 0 {
		needs += " devel"
	}
	if len(test.list) > 0 {
		needs += " test"
	}

	color.Print("RED")
	if needs != "" {
		display.Task(role_ref, "\t|<<<Needs"+needs)
	}
	for _, t := range anal.list {
		fmt.Print("A: ")
		display.Task(t, "(analyze)")
	}

	for _, t := range devel.list {
		fmt.Print("D: ")
		display.Task(t, "(do)")
	}

	for _, t := range ick.list {
		color.Print("CYAN")
		fmt.Print("I: ")
		display.Task(t, "(ick)")
		color.Print("")
	}

	for _, t := range test.list {
		fmt.Print("T: ")
		display.Task(t, "(test)")
	}

	for _, t := range repo.list {
		color.Print("BROWN")
		fmt.Print("R: ")
		display.Task(t, "(reprocess/reprint wiki)")
	}

	for _, t := range wiki.list {
		color.Print("PURPLE")
		fmt.Print("W: ")
		display.Task(t, "(update wiki)")
	}
}

func check_state(t *task.Task, want byte, lp *ListSet) {

	if t.State != want {
		return
	}
	lp.list = append(lp.list, t)
}

func check_title(pref *task.Task) {

	title := pref.Title

	if title != task.StripWiki(title) {
		return
	}

	display.Task(pref, "\t| !!! no wiki title")
}
