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

//-- Merge Projects (first list is receiver)
func Report_merge(args []string) int {
	if len(args) < 2 {
		fmt.Printf("No projects to merge\n")
		return 1
	}

	master_id := args[0]
	args = args[1:]

	master := meta.Find(master_id)
	if master == nil {
		return 2
	}
	for _, slave_id := range args {
		slave := meta.Find(slave_id)
		if slave == nil {
			return 2
		}
	}
	for _, slave_id := range args {
		slave := meta.Find(slave_id)

		merge_project(master, slave)
		master.Update()
		slave.Delete()
	}
	return 0
}

func merge_project(master, slave *task.Task) {

	sep := false

	//print "Merge: master\n"; dump_task(master)
	//print "With:  slave\n"; dump_task(slave)

	//##	Merge: type
	if slave.Has_decendent(master) {
		fmt.Printf("merge of slave would fook master\n")
		return
	}

	//##	Merge: title
	//##	Merge: description
	desc := display.Chomp(master.Description)

	// add slave's title  to master's description
	if master.Title != slave.Title {
		if desc != "" {
			desc += "\n------------------------------\n"
		}
		desc += "\n" + display.Chomp(slave.Title) + "\n"
		sep = true
	}

	if slave.Description != "" {
		if sep {
			desc += "\n------------------------------\n"
		}
		desc += slave.Description
	}
	master.Set_description(desc)

	//##	Merge: desiredOutcome
	note := display.Chomp(master.Note)

	snote := display.Chomp(slave.Note)
	if snote != "" && snote != note {
		if note != "" {
			note += "\n------------------------------\n"
		}
		note += snote
		master.Set_note(note)
	}

	//##	Merge: category
	//##	Merge: context
	//##	Merge: timeframe
	merge_cct(master, slave, "category")
	merge_cct(master, slave, "context")
	merge_cct(master, slave, "timeframe")

	//##	Merge: created (dateCreated)
	//##	Merge: due (deadline)
	//##	Merge: tickledate (tickleDate)
	merge_date(master, slave, "created")
	merge_date(master, slave, "due")
	merge_date(master, slave, "tickledate")

	//##	Merge: completed (dateCompleted)
	merge_completed(master, slave)

	//##	Merge: nextaction
	//##	Merge: isSomeday
	merge_yn(master, slave, "nextaction", "y")
	merge_yn(master, slave, "isSomeday", "n")

	//##	Merge: recur
	//##	Merge: recurdesc

	//##	Merge: doit
	merge_date(master, slave, "doit")

	master.Set_effort(master.Effort + slave.Effort)

	merge_first(master, slave, "resource")
	merge_tag(master, slave, "depends")
	merge_tag(master, slave, "tags")

	//##	Merge: parentId
	re_parent(master, slave)
}

//TODO change to using values, not the reference
func merge_cct(master, slave *task.Task, key string) { // learn new key

	val := master.Get_KEY(key)
	if val != "" {
		return
	}
	master.Set_KEY(key, slave.Get_KEY(key))
}

//TODO change to using values, not the reference
func merge_date(master, slave *task.Task, key string) { // keep earliest date

	sdate := slave.Get_KEY(key) // grab slave date
	fmt.Printf("S key = %s\n", sdate)
	if sdate == "" {
		return // no date in slave
	}

	mdate := master.Get_KEY(key) // grab master date
	fmt.Printf("M key = %s\n", mdate)

	if mdate == "" { // no master, use slave
		master.Set_KEY(key, sdate)
		fmt.Printf("Date for key set to %s (was missing)\n", sdate)
		return
	}

	// both master and slave exists, keep earlier (lesser)
	if mdate <= sdate {
		return // master lesser, just keep it
	}

	master.Set_KEY(key, sdate) // slave lesser, set it
	fmt.Printf("Date for key set to %s (was %s)\n", sdate, mdate)
}

//TODO change to using values, not the reference
func merge_completed(master, slave *task.Task) { // keep earliest date

	mdate := master.Completed // grab master date
	if mdate == "" {
		return // no master completed date
	}

	fmt.Printf("M done = %s\n", mdate)

	sdate := slave.Completed // grab slave date
	if sdate == "" {
		return // no slave completed date
	}

	fmt.Printf("S done = %s\n", sdate)

	// both master and slave exists, later (greater)
	if mdate >= sdate { // master greater, just keep it
		return
	}

	master.Set_completed(sdate) // slave greater, set it
	fmt.Printf("Done Date set to %s (was %s)\n", sdate, mdate)
}

//TODO change to using values, not the reference
func merge_yn(master, slave *task.Task, key string, want string) { // update item's importance

	val := master.Get_KEY(key)
	sval := slave.Get_KEY(key)
	if sval == "" {
		return
	}
	if val == slave.Get_KEY(key) {
		return
	}
	if val == want {
		return
	}
	master.Set_KEY(key, slave.Get_KEY(key))
}

//TODO change to using values, not the reference
func merge_first(master, slave *task.Task, key string) { // update item's importance

	val := master.Get_KEY(key)

	if val != "" { // master has a value keep it
		return
	}

	sval := slave.Get_KEY(key)

	if sval == "" { // slave doesn't have a value ... done
		return
	}

	master.Set_KEY(key, val) // slave has a value, set it
}

//TODO change to using values, not the reference
func merge_tag(master, slave *task.Task, key string) { // update item's importance

	sval := slave.Get_KEY(key)

	if sval == "" { // slave doesn't have a value ... done
		return
	}

	mval := master.Get_KEY(key)

	if mval != "" {
		master.Set_KEY(key, mval+","+sval) // both have vals
	} else {
		master.Set_KEY(key, sval) // slave only has a value
	}
}

// find all children of slave and give them a new master.
func re_parent(master, slave *task.Task) {

	for _, child := range slave.Children {
		fmt.Printf("move S child %d\n", child.Tid)

		slave.Orphin_child(child)
		master.Add_child(child)
	}
}
