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
import "log"
import "strings"
import "strconv"

import "gtd/meta"

//X import "gtd/display"
import "gtd/option"
import "gtd/task"

var tj_ToOld string
var tj_ToFuture string

var tj_Someday bool = false

var Dep_list = map[int]string{}

//-- generate taskjuggler file from gtd db
func Report_taskjuggler(args []string) int {
	meta.Filter("+active", "^focus", "none")

	//my($tid, $task, $cat, $ins, $due, $desc)

	tj_ToOld = pdate(option.Today(-7)) // don't care about done items > 2 week
	tj_Someday = option.Get("filter", "") == "+all"

	if tj_Someday {
		// 5 year plan everything plan
		tj_ToFuture = pdate(option.Today(5 * 365))
	} else {
		// don't care about start more > 3 months
		tj_ToFuture = pdate(option.Today(60))
	}

	if len(args) == 0 {
		args = []string{"role"}
	}

	w := meta.Walk(args)
	w.Pre = build_deps
	w.Detail = juggler_detail
	w.Done = juggler_end

	w.Set_depth('a')
	w.Filter()

	tj_header()

	w.Walk()

	return 0
}

func calc_est() int {
	hours := 0
	task := 0

	for _, t := range meta.Selected() {
		task++

		r := t.Project()
		hours += r.Hours()
	}
	days := hours / 4

	log.Printf("Tasks: %d Est days %d (min 90)\n", task, days)

	if days < 90 {
		days = 90
	}
	return days
}

func tj_header() {
	est := calc_est()
	projection := pdate(option.Today(est))

	fmt.Printf(`
project GTD "Get Things Done" "1.0" %s - %s {
  # Hide the clock time. Only show the date.
  timeformat "%s"

  # The currency for all money values is CAN
  currency "CAN"
  weekstartssunday

  # We want to compare the baseline scenario, to one with a slightly
  # delayed start.
  scenario plan "Plan" {
    scenario done "Done"
  }
}

include "Triad-resource.tji"
include "Triad-reports.tji"

`, tj_ToOld, projection, "%Y-%m-%d")

}

func juggler_detail(w *task.Walk, t *task.Task) {
	tid := t.Tid

	indent := Indent(t)
	r := t.Project()

	name := t.Title
	tj_pri := task_priority(t)
	//X desc := display.Summary(t.Description, "")
	//X note := display.Summary(t.Note, "")
	kind := t.Type
	//X per := 0
	//X if t.Completed != "" {
	//X 	per = 100
	//X }
	due := pdate(t.Due)
	done := pdate(t.Completed)
	start := pdate(t.Tickledate)
	//X doit := pdate(t.Doit)
	depends := t.Depends

	user := r.Resource()
	hint := r.Hint()

	rdebug("## detail: %d %s %c %s\n", tid, tj_pri, kind, name)

	if skip(w, t) {
		return
	}

	if start != "" && start < tj_ToOld {
		start = ""
	}

	//X log.Printf("tj setting who to drew...")
	//X who := "drew"

	//X effort := r.Effort()

	if due != "" && due < "2010-" {
		due = ""
	}
	we := due

	pri := t.Priority
	if pri >= 6 {
		we = ""
	}

	fd := w.Fd

	name = strings.Replace(name, `"`, "'", -1)
	fmt.Fprintf(fd, "%stask %c_%d \"%s\" {\n", indent, kind, tid, name)

	if indent == "" {
		fmt.Fprintf(fd, "%s    start %s\n", option.Today(0))
		fmt.Fprintf(fd, "%s    allocate %s { mandatory } # %s\n",
			indent, user, hint)
	} else {
		if user != "" && parent_user(t) != user {
			fmt.Fprintf(fd, "%s    allocate %s { mandatory } # %s\n",
				indent, user, hint)
		}
	}

	for _, depend := range strings.Split(depends, " ,") {
		dep_path := get_dep_path(depend)

		if dep_path == "" {
			log.Printf("depend %d: needs %s failed to produce path!", tid, depend)
			continue
		}
		if task.Is_comment(dep_path) { // =~ /^\s*#/
			log.Printf("depend %d: no-longer depends: %s %s\n",
				tid, depend, dep_path)
			continue
		}

		log.Printf("depend %d: %s dep_path %s\n",
			tid, depend, dep_path)
		fmt.Fprintf(fd, "%s    depends %s\n", indent, dep_path)
	}

	//##BUG### taskjuggler need to check for un-filtered children for effort
	if len(t.Children) > 0 {
		// nope has children, we just accumlate effort in them
	} else {
		/*?
		if effort {
			t._effort++
		}
		?*/
		fmt.Fprintf(fd, "%s    effort %s\n", indent, r.Effort())
	}

	if tj_pri != "" {
		fmt.Fprintf(fd, "%s    priority %s\n", indent, tj_pri)
	}
	if start != "" && we == "" {
		fmt.Fprintf(fd, "%s    start %s\n", indent, start)
	}
	if we != "" && we > tj_ToOld {
		fmt.Fprintf(fd, "%s    maxend %s\n", indent, we)
	}
	if done != "" {
		fmt.Fprintf(fd, "%s    complete  100\n", indent)
	}

}

func Indent(t *task.Task) string {
	level := t.Level() - 1

	if level < 0 {
		return ""
	}

	return strings.Repeat("   ", level)
}

func juggler_end(w *task.Walk, t *task.Task) {

	if skip(w, t) {
		return
	}

	fd := w.Fd
	indent := Indent(t)

	//X pref := t.Parent()
	//X pref._effort++

	fmt.Fprintf(fd, "%s   effort %s\n", indent, "4h")
	log.Printf("Task %d: %s |<<< Needs effort planning\n", t.Tid, t.Title)

	if t.Is_hier() { // $type =~ /[mvog]/)
		fmt.Fprintf(fd, "%s} # %c_%d \n", indent, t.Type, t.Tid)
		return
	}
	fmt.Fprintf(fd, "%s}\n", indent)
}

func pdate(date string) string {
	if date == "" {
		return ""
	}

	if i := strings.Index(date, " "); i >= 0 {
		date = date[:i]
	}
	return date

}

func parent_user(t *task.Task) string {
	pref := t.Parent()
	if pref == nil {
		return ""
	}

	r := pref.Project()
	return r.Resource()
}

func tp(s string, i int) int {
	if len(s) <= i {
		return 0
	}

	// `abcdefghijklmnoz`,
	// `9987766544321000`))
	switch s[i] {
	case 'a', 'b':
		return 9
	case 'c':
		return 8
	case 'd', 'e':
		return 7
	case 'f', 'g':
		return 6
	case 'h':
		return 5
	case 'i', 'j':
		return 4
	case 'k':
		return 3
	case 'l':
		return 2
	case 'm':
		return 1
	}
	return 0
}

func task_priority(t *task.Task) string {
	pf := task.Calc_focus(t)

	tj_pri := tp(pf, 2)*100 + tp(pf, 3)*10 + tp(pf, 4)

	if tj_pri > 1000 {
		tj_pri = 1000
	}
	if tj_pri < 1 {
		return ""
	}

	pfz := pf + "   "
	return fmt.Sprintf("%d # %s.%s", tj_pri, pfz[0:2], pfz[2:])

}

func skip(w *task.Walk, t *task.Task) bool {

	start := pdate(t.Tickledate)
	done := pdate(t.Completed)

	if !tj_Someday && t.Is_someday() {
		supress(w, t)
		return true
	}

	if done != "" {
		supress(w, t)
		return true
	}
	if start != "" && start > tj_ToFuture {
		supress(w, t)
		return true
	}

	return false
}

func supress(w *task.Walk, t *task.Task) {
	w.Want[t] = false

	for _, child := range t.Children {
		supress(w, child)
	}
}

//==============================================================================

func build_deps(w *task.Walk, t *task.Task) {
	tid := t.Tid
	if _, ok := Dep_list[tid]; ok {
		return
	}

	// return if skip(w, t)

	path := fmt.Sprintf("%c_%d", t.Type, tid)

	level := t.Level()
	if level == 1 {
		Dep_list[tid] = path
		return
	}

	pref := t.Parent()
	pid := pref.Tid

	if v, ok := Dep_list[pid]; ok {
		path := v + "." + path
		Dep_list[tid] = path

		return
	}

}

func get_dep_path(task_id string) string {
	tid, err := strconv.Atoi(task_id)
	if err != nil {
		return ""
	}
	t := task.Find(tid)
	if t == nil {
		return ""
	}

	path := Dep_list[tid]

	if path != "" {
		return fmt.Sprintf("%s # %s", path, t.Title)
	}

	fmt.Printf("# Can't map %d (%s) as a depencency\n", tid, t.Title)
	log.Printf("# Can't map %d (%s) as a depencency\n", tid, t.Title)

	return ""
}

func rdebug(f string, v ...interface{}) {
	return
	fmt.Printf(f, v...)
}
