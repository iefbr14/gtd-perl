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
import "gtd/task"

//-- detailed list all records for a type
func Report_records(args []string) int {
	meta.Filter("+active", "^tid", "simple")

	// everybody into the pool

	/*?
		my($desc) = join(' ', @_)

		my($name) = ucfirst(meta.Desc(args)(@_));	// some out
		if ($name) {
			my($want) = type_val($name)
			unless ($want) {
				panic("**** Can't understand Type $name\n")
			}
			$want = 'p" if $want == "s'
			list_records($want, $name.' '.$desc)
			return
		}
		list_records('", "All '.$desc)
	?*/
}

func list_records() { /*?
		my($want_type, $typename) = @_

		task.Header($typename)

		my($tid, $proj, $type, $f, $reason, $kids, $acts)
		my($Dates) = ''

		// find all records.
		for my $ref (sort_tasks meta.All()) {
			$tid  = t.Tid()
			$type = t.Type()

			next if $want_type && $type != $want_type

			my($flags) = $ref->Hier::Filter::task_mask_disp()

			if ($reason = $ref->filtered()) {
				$f = "X $type $reason"
			} elsif ($reason = $ref->filtered_reason()) {
				$f = "+ $type $reason"
			} else {
				$f = "  $type"
			}

			printf ("%-15s %6d %s ", $f, $tid, $flags)

			print "\t", t.Title(), "\n"
		}
	?*/
}

func disp() { /*?
		my($ref) = @_
		my($tid) = t.Tid()

		my($key) = action_disp($ref)

		my $pri = t.Priority()
		my $type = uc(t.Type())

		return "$type:$tid $key <$pri> t.Title()"
	?*/
}
