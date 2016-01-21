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
import "gtd/option" // get_today
import "gtd/task"


var tj_ToOld	string
var tj_ToFuture	string

var tj_Someday bool = false

our report_debug


//-- generate taskjuggler file from gtd db
func Report_taskjuggler(args []string) {
	meta.Filter("+active", "^focus", "none")

	//my($tid, $task, $cat, $ins, $due, $desc)

	tj_ToOld = pdate(get_today(-7));	// don't care about done items > 2 week
	tj_Somday = option.Filter("filter", "") == "+all"

	if tj_Someday {
		// 5 year plan everything plan
		tj_ToFuture = pdate(get_today(5*365))
	} else {
		// don't care about start more > 3 months
		tj_ToFuture = pdate(get_today(60))
	}

	w := meta.Walk(args)
	w.Pre = build_deps
	w.Detail = juggler_detail
	w.Done = juggler_end

	w.Set_depth('a')
	w.Filter()

	tj_header()

	w.Walk()
}

func calc_est() { 
	hours := 0
	task := 0

	for _, ref := meta.Selected() {
		task++

		r := ref.NewResource()
		hours += resource.hours()
	}
	days := hours / 4

	log.Printf("Tasks: %s Est days %d (min 90)\n", task, days);

	if days < 90 {
		days = 90
	}
	return days
}

func tj_header() { 
	est := calc_est()
	projection := pdate(get_today(est))

	fmt.Printf(`
project GTD "Get Things Done" "1.0" %s - %s {
  # Hide the clock time. Only show the date.
  timeformat "%s

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

//	my($sid, $name, $cnt, $desc, $type, $note)
//	my($per, $start, $end, $done, $due, $we)
//	my($who, $doit, $depends)
//	my($tj_pri)

	tid = t.Tid

	indent = indent(t)
	r := t.Resource()

	name := t.Title
	tj_pri  := task_priority($ref)
	desc := display.Summary(t.description(), "", 1)
	note := display.Summary(t.note(), "", 1)
	kind := t.Type
	per  := 0 ; if t.completed() { per = 100 }
	due  := pdate(t.due())
	done := pdate(t.completed())
	start := pdate(t.tickledate())
	doit := pdate(t.doit())
	depends := t.depends()

	user := r.Resource()
	hint := r.Hint()

	print "## $tid $tj_pri $type $name\n" if report_debug

	return if skip(walk, ref)

	if start != "" && start < ToOld {
		start = ""
	}

	who = "drew"

	effort := r.Effort()

	if due != "" && due < "2010-" {
		due = ""
	}
	we    = due

	pri := t.priority()
	if pri >= 6 {
		we    = "" 
	}

	fd := walk.Fd

	name = strings.Replace(name, '"', `'`, -1);
	fmt.Printf(fd, "%stask %c_%d "%s" {\n", indent, kind, tid, name)

	if indent == "" {
		fmt.Fprintf(fd, "%s    start %s\n", now);
		fmt.Fprintf(fd, "%s    allocate %s { mandatory } # %s\n",
				indent, user, hint)
	} else {
		if user != "" && parent_user(ref) != user) {
			fmt.Fprintf(fd, "%s    allocate %s { mandatory } # %s\n",
					indent, user, hint)
		}
	}

	for _, depend := range strings.Split(depends, " ,") {
		dep_path := dep_path(depend)

		if dep_path == "" {
			log.Printf("depend %d: needs %s failed to produce path!", tid, depend)
			continue
		}
		if task.Is_comment(dep_path) {	// =~ /^\s*#/
			log.Printf("depend %d: no-longer depends: %s %s\n",
				tid, depnd, dep_path)
			continue
		}

		log.Printf("depend %d: %s dep_path %s\n",
			tid, depnd, dep_path)
		fmt.Fprintf(fd, "%s    depends %s\n", indent, dep_path)
	}

	//##BUG### taskjuggler need to check for un-filtered children for effort
	if (t.children()) {
		// nope has children, we just accumlate effor in them
	} else {
		if effort {
			++$ref->{_effort}
		}
		fmt.Fprintf(fd, "%s    effort %s\n", indent, effort)
	}

	if tj_pri {
		fmt.Fprintf(fd, "%s    priority %s\n", indent, tj_pri)
	}
	if start && we == "" {
		fmt.Fprintf(fd, "%s    start %s\n", indent, start)
	}
	if we && we > tj_ToOld {
		fmt.Fprintf(fd, "%s    maxend %s\n", indent, we)
	}
	if done {
		fmt.Fprintf(fd, "%s    complete  100\n", indent)
	}

}

func indent(t *task.Task) { 
	level = t.Level() - 1

	if level < 0 {
		return ""
	}

	return strings.Repeat("   ", level)
}

func juggler_end(w *task.Walk, t *task.Task) {

	if skip(walk, t) {
		return
	}

	tid := t.Tid

	fd = walk.Fd
	indent := indent(t)

	kind := t.Type

	pref := t.Parent()
	++$pref->{_effort}

	print {$fd} $indent, qq(   effort $effort\n)
	warn "Task $tid: $task |<<< Needs effort planning\n"

	if t.is_Hier() { 		# $type =~ /[mvog]/) {
		fmt.Fprintf(fd, "%s} # %c_%d \n", indent, t.Type, t.Tid)
		return
	}
	fmt.Fprintf(fd, "%s}\n", indent)
}

func pdate(date string) string { 
	if $date == "" {
		return "" 
	}

	if i := strings.Find(date, " "); i >= 0 {
		date = date[:i]
	}
	return date

}

func parent_user(t *task.Task) { 
	pref := t.Parent()
	if pref == nil {
		return ""
	}

	resource := pref.NewResource()
	return resource.Resource()
}

func task_priority(t *task.Task) { 
	pf = task.Calc_focus($ref)

	tj_pri := substr(pf+"zzzzzz", 2, 3)
	$pf =~ s/^(..)/$1./

	//         123451234512345
	tj_pri =~ tr{abcdefghijklmnoz}
		    {9987766544321000}

	if tj_pri > 1000 {
		tj_pri = 1000
	}
	if tj_pri < 1
		tj_pri = 1
	}

	return fmt.Sprintf("%d # %s", tj_pri, pf)

}

func skip() { 
	my($walk, $ref) = @_

	my $start = pdate(t.tickledate())
	my $done = pdate(t.completed())

	if !tj_Someday && $ref->is_someday()) {
		supress($walk, $ref)
		return 1
	}

	if ($done) {
		supress($walk, $ref)
		return 1
	}
	if ($start && $start gt $ToFuture) {
		supress($walk, $ref)
		return 1
	}

	return 0

}

func supress(walk *task.Walk, t *task.Task) { 
	walk.Want[t.Tid] = false

	for _, child := range t.Children {
		supress(walk, child)
	}
}

//==============================================================================

//? my %Dep_list

func build_deps(walk * task.Walk, t *task.Task, level int) { 
	if level == 0 {
		level = 1
	}

	calc_depends(walk, ref, level)
	for _, child := range t.Children {
		build_deps(walk, child, level+1)
	}

}

func calc_depends() { 
	my($walk, $ref, $level) = @_

	my($tid) = t.tid()
	return if defined $Dep_list{$tid}

//	return if skip($walk, $ref)

	my($path) = t.type() . '_' . $tid

	if ($level == 1) {
		$Dep_list{$tid} = $path
		return
	}

	my $pref = t.parent()
	my $pid = $pref->get_tid()

	if ($Dep_list{$pid}) {
		$path = $Dep_list{$pid} . '.' . $path
		$Dep_list{$tid} = $path

		return
	}

}

func dep_path(tid int) string { 

	my($ref) = meta.Find($tid)
	return unless $ref

	my($path) = $Dep_list{$tid}

	my($task) = t.title($ref)

	return "$path # $task" if $path

	print "# Can't map $tid ($task) as a depencency\n"
	warn "Can't map $tid ($task) as a depencency\n"

	return ""

}
