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

import "gtd/perl"

//-- List next actions
func Report_nextactions(args []string) {
	meta.Filter("+next", "^title", "none")

	//?my($tid, $pid, $pref, $tic, $parent, $pic, $name, $desc)
	//?my(@row)

	fmt.Print(`
-Par [-] Parent           -Tid [-] Next Action
==== === ================ ==== === ============================================
`)

	perl.Format("HIER", `
@>>> @<< @<<<<<<<<<<<<<<< @>>> @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$pid, $pic, $parent,      $tid, $tic, $name,
`)

	for _, ref := range meta.Pick("actions") {
		tid := t.Tid
		//#FILTER	next unless $ref->is_nextaction()
		//#FILTER	next if $ref->filtered()

		name := t.Title()
		tic = action_disp(ref)

		pref = t.Parent()
		//next unless $pref->is_nextaction()
		var pid int
		var parent string
		if pref != nil {
			parent = pref.Title
			pid = pref.Tid
		} else {
			parent = "-orphined-"
			pid = "--"
		}
		pic = task.Type_disp(pref)

		write
	}
}
