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

import "strings"

import "gtd/meta"
import "gtd/display"

//-- list all items without a parent
func Report_orphans(args []string) {
	meta.Filter("+any", "^title", "todo")

	_ = meta.Pick(args)

	display.Header("Orphans -- " + strings.Join(args, " "))

	for _, ref := range meta.Sorted() {

		// Values never have parents
		if ref.Type == 'm' {
			continue
		}

		// Has a parent
		if len(ref.Parents) > 0 {
			continue
		}

		display.Task(ref, "")
	}
}
