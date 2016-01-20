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
import "gtd/option"

//-- clean unused categories
func Report_clean(args []string) {
	meta.Filter("+all", "^tid", "task")
	/*?
		my $Yesterday = get_today(-1)

		my($done, $tickle, $type)

		for my $ref (meta.elected()) {
			$done = $ref->is_completed()
			if ($done) {
				set_active($ref)
				fix_done_0000($ref, $done)
				clear_next($ref)
				clear_tickle($ref)
			}

			$tickle = $ref->get_tickledate() <= $Yesterday
			if ($tickle) {
				clear_next($ref)
				clear_tickle($ref)
			}

			$type = $ref->get_type()

			// all values and visions are active
			if ($type =~ /[mv]/) {
				set_active($ref)
			}
		}
	?*/
}

func set_active() { /*?
		my($ref) = @_

		if ($ref->is_someday()) {
			$ref->set_isSomeday('n')
			display_task($ref, "active")
			return
		}
		return
	?*/
}

func fix_done_0000() { /*?
		my($ref, $done) = @_

		return unless $done =~ /^0000/

		display_task($ref, "clean done bug")
		$ref->set_completed(undef)
		return
	?*/
}

func clear_next() { /*?
		my $ref = @_

		return unless $ref->get_nextaction() == 'y'

		display_task($ref, "clear next action")
		$ref->set_nextaction('n')
	?*/
}

func clear_tickle() { /*?
		my $ref = @_

		return unless $ref->get_tickledate()

		display_task($ref, "clear tickle date")
		$ref->set_tickledate(undef)
	?*/
}
