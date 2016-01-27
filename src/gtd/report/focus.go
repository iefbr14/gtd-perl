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

import "gtd/meta"
import "gtd/task"
import "gtd/display"

var Work_load int = 0
var Proj_cnt int = 0
var Dep *task.Task // Project depends on string

//-- List focus -- live, plan or someday
func Report_focus(args []string) int {
	meta.Filter("+next", "^focus", "simple")

	var list task.Tasks

	if len(args) == 0 {
		list = meta.Pick([]string{"Role"})
		display.Header("Focus Role")
	} else {
		list = meta.Pick(args)

		if task.MatchId(args[0]) {
			t := list[0]

			title := fmt.Sprintf("%d: %s", t.Tid, t.Title)

			display.Header(task.Join(" ", "Focus", title))
		} else {
			display.Header(task.Join(" ", "Focus", args[0]))
		}
	}

	// find all next and remember there focus
	for _, t := range list.Sort() {
		if !check_task(t) {
			display.Rgpa(t, "(PLAN)")
		}
	}
	fmt.Printf("***** Work Load: %d Projects, %d action items\n", Proj_cnt, Work_load)
	return 0
}

//##BUG -- borks if dep on completed item
//## Re-thing whole logic
func check_task(t *task.Task) bool {
	id := t.Tid

	if report_debug {
		fmt.Printf("X %d %s\n", id, t.Title)
	}

	if t.Depends != "" {
		deps := t.Depends

		//? $deps =~ s/\s+/,/g
		for _, dep := range strings.Split(deps, ",") {
			if report_debug {
				fmt.Printf("Deps %d on %s\n", id, deps)
			}

			d_ref := meta.Find(dep)
			if d_ref == nil {
				fmt.Printf("Info: task %d depends on missing task %s\n", id, dep)
				continue
			}

			Dep = t
			if check_task(d_ref) {
				Dep = nil
				return true
			}
			Dep = nil
		}
		if report_debug {
			fmt.Printf("No actions for %d on %s\n", id, deps)
		}
		return false
	}

	if t.Type == 'a' {
		if Dep != nil {
			display.Rgpa(Dep, "(DEP)")
			fmt.Print("--- ( Depends On ) ----\n")
			display.Rgpa(t, "=")
		} else {
			display.Rgpa(t, "")
		}
		return true
	}

	for _, ref := range t.Children.Sort() {
		if !ref.Is_nextaction() {
			continue
		}
		if ref.Completed != "" {
			continue
		}
		//#FILTER#	next if $ref->filtered()

		if ref.Type == 'p' {

			work, _ := display.Summary_children(t)
			Work_load += work

			Proj_cnt++
		}

		if check_task(ref) {
			return true
		}
	}
	return false
}
