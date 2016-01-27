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

//-- List all top level item (Project and above)
func Report_hierlist(args []string) {
	meta.Filter("+p:live", "^title", "simple")
	/*?
	  	my($tid, $pid, $pref, $cnt, $parent, $cat, $name, $desc)
	  	my(@row)

	  	meta.Desc(args)(@_)

	  print <<"EOF"
	  -Gtd -Par Cnt Category  Parent       Name         Description
	  ==== ==== === ========= ============ =========== ==============================
	  EOF

	  format HIER   =
	  @>>> @>>> @>> @<<<<<<<< @<<<<<<<<<<< @<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	  $tid, $pid,$cnt,$cat,     $parent,     $name,      $desc
	  .
	  	$~ = "HIER";	// set STDOUT format name to HIER

	  	for my $ref (meta.Selected()) {
	  		$tid = t.Tid()

	  //#FILTER	next if $ref->filtered()

	  		$cnt = $ref->count_children() || ''

	  		$cat = t.Category() || ''
	  		$name = t.Title() || ''
	  		$desc = t.Description() || ''

	  		$pref = t.Parent()
	  		if (defined $pref) {
	  			$parent = $pref->get_title()
	  			$pid = $pref->get_tid()
	  		} else {
	  			$parent = "orphined"
	  			$pid = "--"
	  		}

	  		write
	  	}
	  ?*/
}
