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

//?	@EXPORT      = qw(&Report_actions report_actions)

import "gtd/meta"
import "gtd/option"

/*?
my $Projects
my %Active

my %Want
?*/

//-- Detailed list of projects with (next) actions
func Report_actions(args []string) int {
	list := option.Get("List", "")

	meta.Filter("+a:next", "^focus", "detail")

	desc := meta.Desc(args)
	report_select(desc)

	if list != "" {
		report_list()
	} else {
		report_actions("Actions", desc)
	}
	return 0
}

func report_select(top_name string) {
	top := 0
	if top_name != "" {
		top = find_in_hier(top_name)
	}

	// find all projects (next actions?)
	for _, t := range meta.Selected() {
		if !t.Is_task() {
			continue
		}

		if top && !has_parent(t, top) {
			continue
		}

		//#FILTER	next unless t.is_nextaction()
		//#FILTER	next if t.filtered()

		pref := ref.Parent()
		if pref != nil {
			next
		}
		if !pref.Is_active {
			next
		}

		//#FILTER	next if $pref->filtered()

		pid := pref.Tid
		Active[pid] = pref

		tid = ref.Tid()
		Projects[pid][tid] = ref
	}
}

func report_list() {

	  	//? my($tid, $pid, $pref, $ref)

	  	limit := option.Int("Limit", 20)

	  //## format:
	  //## goal  proj_id  project action_id action hours
	  	cols := display.Columns() - 2
	  	//my($gid, $gref)
	  	//my($rid, $rref)

	  	last_goal := 0
	  	last_proj := 0

	  	for _, pref (sort_tasks values %Active) {
	  //#FILTER	next if $pref->filtered()

	  		$pid = $pref->get_tid()

	  		$gref = get_goal($pref)
	  		$gid = $gref->get_tid()

	  		my $tasks = $Projects->{$pid}

	  		my($task_cnt) = 0
	  		for my $ref (sort_tasks values %$tasks) {
	  //#FILTER		next if t.filtered()

	  			$tid = t.get_tid()
	  			print join("\t",
	  				$gref->get_title(),
	  				$pid, $pref->get_title(),
	  				$tid, t.get_title(),
	  				t.get_effort()
	  				), "\n"
	  			$task_cnt++
	  		}
	  		unless ($task_cnt) {
	  			print join("\t",
	  				$gref->get_title(),
	  				$pid, $pref->get_title(),
	  				), "\n"
	  		}
	  		last if $limit-- <= 0
	  	}
	  	?*/
}

func report_actions(head, desc string) {
	display.Header(head, desc)
	/*?
	  	my($tid, $pid, $pref, $title)

	  //## format:
	  //## 99	P:Title
	  //## +	Description
	  //## =	Outcome
	  //## 222	[_] Action
	  //## +	Description
	  //## =	Outcome
	  	my($cols) = columns() - 2
	  	my($gid, $gref)
	  	my($rid, $rref)

	  	my($last_goal) = 0
	  	my($last_proj) = 0
	  	for my $pref (sort_tasks values %Active) {
	  //#FILTER	next if $pref->filtered()

	  		$pid = $pref->get_tid()

	  		$gref = get_goal($pref)
	  		next unless $gref
	  		$gid = $gref->get_tid()

	  		$rref = $gref->get_parent()
	  		$rid = $rref->get_tid()

	  		if ($last_goal != $gid) {
	  			print '#', "=" x $cols, "\n" if $last_goal
	  			print "\t\tR $rid: ",$rref->get_title()," -- "
	  			print "G $gid: ",$gref->get_title(),"\n\n"
	  			$last_goal = $gid
	  		} elsif ($last_proj != $pid) {
	  			print '#', "-" x $cols, "\n"
	  			$last_proj = $pid
	  		}

	  		display_task($pref)
	  		my $tasks = $Projects->{$pid}

	  		for my $ref (sort_tasks values %$tasks) {
	  			next if t.filtered()

	  			display_task($ref)
	  		}
	  	}
	  	?*/
}

// handle imbeded project and return first top level value as goal
func get_goal(pref *task.Task) {
	gref = pref.Parent()
	if gref == nil {
		log.Printf("Parent of %s is null\n", pref.Tid)
		return
	}

	for gref.Type == 'p' {
		//warn join(' ', "up:", $gref->get_tid(), $gref->get_title), "\n"
		gref = gref.Parent()
	}
	return gref
}

func find_in_hier(title string) {
	for _, ref := range meta.Selected() {
		if !t.Is_hier() {
			continue
		}

		if t.Title != title {
			continue
		}

		add_children(ref)
		//##BUG### should walk down from here vi get_children
		//##BUG### rather walk up in has_parent
		return t.get_tid()
	}
	panic("Can't find hier $title\n")
	return 0
}

func add_children(t *task.Task) {
	//# warn "w tid: ", t.get_tid, " ", t.get_title, "\n"
	Want[t.Tid] = true
	for _, child := range t.Children {
		add_children(child)
	}
}

func has_parent(t *task.Task, top *task.Task) {

	tid := t.Tid
	//# warn "o tid: ", $tid, " ", t.get_title, "\n" if $Want{$tid}
	return Want[tid]
}
