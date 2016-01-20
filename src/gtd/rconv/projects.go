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

import "gtd/task"
import "gtd/meta"
import "gtd/option"

//?my %Meta_key

//-- List projects -- live, plan or someday
func Report_projects(args []string) int {
	meta.Filter("+next", "^focus", "rgpa")

	//meta.Filter("+p:next", '^focus', "simple")

	display.Header("Projects", meta.Desc(args))

	work_load := 0
	proj_cnt := 0

	wanted := map[int]*task.Task{}
	counted := map[int]int{}
	actions := map[int]int{}

	// find all next and remember there projects
	for _, ref := range meta.Matching_type('p') {
		//#FILTER	next if ref->filtered()

		pid := ref.Tid
		wanted[pid] = ref
		counted[pid] = 0
		actions[pid] = 0

		for _, child := range ref.Children {
			if !child.filtered() {
				work_load++
			} else {
				counted{pid}++
			}
			actions{pid}++

		}
	}

	//## format:
	//## ==========================
	//## Value Vision Role
	//## -------------------------
	//## 99	Goal 999 Project

	g_id := 0
	prev_goal := 0

	r_id := 0
	prev_role := 0

	//? (sort by_goal_task values %wanted)
	for _, ref := range wanted.Sort_by_goal_task {

		work, counts := summary_children(ref)
		work_load += work
		display.Rgpa(ref, counts)
		// display.Task(ref, counts)

		proj_cnt++

	}
	fmt.Print("***** Work Load: proj_cnt Projects, work_load action items\n")
}
