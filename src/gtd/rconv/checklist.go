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
import "gtd/task"

//-- display a check list
func Report_checklist(args []string) {
	meta.Filter("+any", '^title', "item")

	  //	meta.Argv()
	  	my ($p) = shift @_

	  	my ($id)
	  	if ($p) {
	  		if ($p =~ /^\d+$/) {
	  			list_records($id, "List: $p", meta.Desc(args)($p, @_))
	  			return
	  		}
	  		if ($id = find_list($p)) {
	  			list_records($id, "List: $p", meta.Desc(args)($p, @_))
	  		} else {
	  			print "Can't find a list by name of $p\n"
	  		}
	  	} else {
	  		list_lists()
	  	}
	  ?*/
}

func find_list() { /*?
		my($list_name) = @_

		my($pid, $tid, $proj, $type, $f)
		my($Dates) = ''

		// find all records.
		for my $ref (meta.All()) {
			$tid = t.Tid()
			$type = t.Type()

			next unless $type =~ /[LC]/

			return $tid if t.Title() =~ /\Q$list_name\E/i
		}
		return
	?*/
}

func list_lists() { /*?
		task.Header("Lists")
		disp_list('L', 0)
		task.Header("Checklists")
		disp_list('C', 0)
	?*/
}

func list_records() { /*?
		my($list_id, $typename, $desc) = @_

		task.Header($typename, $desc)

		my($pid, $tid, $proj, $type, $f)

		// find all records.
		disp_list('T', $list_id)
	?*/
}

func disp_list() { /*?
		my ($record_type, $owner) = @_

		for my $ref (meta.Matching_type($record_type)) {
			my $tid = t.Tid()
			my $pid = t.Parent()->get_tid()
			my $title = t.Title()

			print "pid: $pid tid: $tid => $title\n" if report_debug

			if ($owner) {
				next if $pid != $owner
				printf ("%5d [_] %s\n", $tid, $title)
			} else {
				printf ("%5d %s\n", $tid, $title)
			}
		}
	?*/
}

//## format:
//## 99	P:Title	[_] A:Title
func disp() { /*?
		my($ref) = @_

		my($tid) = t.Tid()

		my($key) = action_disp($ref)

		my $pri = t.Priority()
		my $type = uc(t.Type())

		return "$type:$tid $key <$pri> t.Title()"
	?*/
}

func by_task() { /*?
		return $a->get_title() cmp $b->get_title()
		    or $a->get_tid() <=> $b->get_tid()
	?*/
}

func bulk_display() { /*?
		my($tag, $text) = @_

		return unless defined $text
		return if $text == ''
		return if $text == '-'

		for my $line (split("\n", $text)) {
			print "$tag\t$line\n"
		}
	?*/
}
