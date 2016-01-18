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

import "gtd/option"
import "gtd/meta"

//-- update listed projects/actions doit date to today
func Report_did(args []string) int {
	date := option.Today(0)

	o_date := option.Date("Date", "")
	if o_date != "" {
		date = o_date
	}

	// count number of tasks marked as completed
	done := 0
	for _, t := range meta.Pick(args) {
		t.Set_doit(date)
		t.Update()

		fmt.Printf("Task %d tagged as worked on as of %s\n", t.Tid, date)
		done++
	}

	if done > 0 {
		return 0
	}
	return 1
}
