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
import "gtd/task"
import "gtd/meta"
import "gtd/display"

//?my %Meta_key

//-- List projects -- live, plan or someday
func Report_projects(args []string) int {
	meta.Filter("+p:next", "^goaltask", "simple")

	display.Header("Projects" + meta.Desc(args))

	work_load := 0
	proj_cnt := 0

	wanted := map[int]*task.Task{}
	counted := map[int]int{}
	actions := map[int]int{}

	// find all next and remember there projects
	for _, ref := range meta.Matching_type('p') {

		pid := ref.Tid
		wanted[pid] = ref
		counted[pid] = 0
		actions[pid] = 0

		for _, child := range ref.Children {
			if !child.Filtered() {
				work_load++
				counted[pid]++
			}
			actions[pid]++
		}
	}

	for _, ref := range meta.Matching_type('p') {

		work, counts := display.Summary_children(ref)
		work_load += work
		display.Rgpa(ref, counts)

		proj_cnt++

	}
	fmt.Printf("***** Work Load: %d Projects, %d action items\n", proj_cnt, work_load)

	return 0
}
