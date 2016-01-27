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

//import "gtd/option"
import "gtd/meta"
import "gtd/task"

var status_Live = map[*task.Task]bool{}

var Class = []string{"Done", "Someday", "Action", "Next", "Future", "Total"}

var (
	Hours_proj int
	Hours_task int
	Hours_next int
)

//-- report status of projects/actions
func Report_status(args []string) int {
	// counts use it and it give a context
	meta.Filter("+active", "^tid", "none")

	desc := meta.Desc(args)

	if strings.ToLower(desc) == "all" {
		report_detail()
		return 0
	}

	Hours_proj = 0
	Hours_task = 0
	Hours_next = 0

	hier := count_hier()
	proj := count_proj()
	task := count_task()
	next := count_next()

	//	print "Options:\n"
	//	for my option (qw(pri debug db title report)) {
	//		printf "%10s %s\n", option, get_info(option)
	//	}
	//	print "\n"

	if desc != "" {
		fmt.Printf("For: %s\n", desc)
		//		t := meta.Task(desc)
		//		print t.Title, "\n"
	}
	total := task + next

	fmt.Printf("hier: %6d  projects: %6d  next,actions: %6d %6d  = %d\n",
		hier, proj, next, task, total)

	t_p := f_h(Hours_proj)
	t_a := f_h(Hours_task)
	t_n := f_h(Hours_next)

	t_time := f_h(Hours_proj + Hours_task + Hours_next)

	fmt.Printf("time:  %6s projects:  %6s next,actions:  %6s %6s = %s\n",
		t_time, t_p, t_n, t_a, f_h(Hours_next+Hours_task))

	fmt.Print("Next")
	for _, kind := range "mvogpsa" {
		n_tid := next_avail_task(byte(kind))
		if n_tid == 0 {
			fmt.Printf("\t%c    -\n", kind)
			continue
		}

		fmt.Printf("\t%c => %d\n", kind, n_tid)
	}
	return 0
}

func f_h(hours int) string {
	switch {
	case hours < 8:
		return fmt.Sprintf("%.1d ", hours)
	case hours < 8*20:
		return fmt.Sprintf("%.1fd", float32(hours)/8)
	case hours < 8*20*15:
		return fmt.Sprintf("%.2fm", float32(hours)/8/20)
	default:
		return fmt.Sprintf("%.3fy", float32(hours)/8/20/12)
	}
}

func count_hier() int {
	count := 0

	// find all hier records
	for _, t := range meta.All() {
		if !t.Is_hier() {
			continue
		}
		if t.Filtered() {
			continue
		}

		count++
	}
	return count
}

func count_proj() int {
	count := 0

	// find all projects
	for _, t := range meta.Matching_type('p') {
		//##FILTER	next if t.Filtered()

		count++

		r := t.Project()
		hours := r.Hours()
		if hours == 0 {
			if len(t.Children) > 0 {
				hours = 1
				// to manage done.
			} else {
				hours = 4
				// to start planning.
			}
		}
		Hours_proj += hours
	}
	return count
}

func count_liveproj() int {
	count := 0

	// find all projects
	for _, t := range meta.Matching_type('p') {
		//##FILTER	next if t.filtered()

		if !project_live(t) {
			continue
		}

		count++
	}
	return count
}

func count_task() int {
	count := 0

	// find all records.
	for _, t := range meta.Selected() {
		if !t.Is_task() {
			continue
		}
		if t.Filtered() {
			continue
		}

		if !project_live(t) {
			continue
		}

		count++

		r := t.Project()
		Hours_task += r.Hours()
	}
	return count
}

func count_next() int {
	count := 0

	// find all records.
	for _, t := range meta.Selected() {
		if !t.Is_task() {
			continue
		}
		if t.Filtered() {
			continue
		}

		if !project_live(t) {
			continue
		}

		if !t.Is_nextaction() {
			continue
		}

		count++

		r := t.Project()
		Hours_next += r.Hours()
	}
	return count
}

func count_tasklive() int {
	count := 0

	// find all records.
	for _, t := range meta.Selected() {
		if !t.Is_task() {
			continue
		}
		if t.Filtered() {
			continue
		}

		if !project_live(t) {
			continue
		}

		count++
	}
	return count
}

func project_live(t *task.Task) bool {
	if live, ok := status_Live[t]; ok {
		return live
	}

	if t.Is_task() {
		if t.Filtered() {
			status_Live[t] = true
			return true
		}

		status_Live[t] = false
		return false
	}

	if t.Is_hier() {
		live := false

		for _, pref := range t.Parents {
			if project_live(pref) {
				live = true
			}
		}
		for _, cref := range t.Children {
			if project_live(cref) {
				continue
			}
		}

		status_Live[t] = live
		return false
	}

	status_Live[t] = false
	return false
}

func calc_type(t *task.Task) byte {

	switch {
	case t.Is_hier():
		return 'h'
	case t.Is_task():
		return 'a'
	default:
		return 'l'
	}
}

func calc_class(t *task.Task) byte {

	switch {
	case t.Completed != "":
		return 'd'
	case t.Is_someday():
		return 's'
	case t.Is_later():
		return 'f'

	case t.Is_nextaction():
		return 'n'
	default:
		return 'a'
	}
}

func report_detail() {
	meta.Filter("+all", "^title", "simple")

	Types := []string{"Hier", "Action", "List", "Total"}
	Class := []string{"Done", "Someday", "Action", "Next", "Future", "Total"}

	data := map[byte]map[byte]int{}

	for _, t := range meta.All() {
		kind := calc_type(t)
		class := calc_class(t)

		data[kind][class]++

		// totals
		data['t'][class]++
		data[kind]['t']++
		data['t']['t']++
	}

	fmt.Printf("   %7s", "Type")
	for _, title := range Class {
		fmt.Printf("   %7s", title)
	}
	fmt.Print("\n---------------------------------------------------------------------------\n")

	for _, kind := range Types {
		tk := lc(kind[0])
		classes := data[tk]

		fmt.Printf("%7s | ", kind)

		for _, class := range Class {
			ck := lc(class[0])
			val := classes[ck]

			fmt.Printf("   %7d", val)
		}
		fmt.Print("\n")
	}
}
func lc(kind byte) byte {
	return kind - 'A' + 'a'
}
