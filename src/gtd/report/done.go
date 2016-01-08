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

import "gtd/option"

//-- Tag listed projects/actions as done
func Report_done(args ...string) {
	date := gtd.Today()

	o_date := gtd.Option("Date", "")
	if o_date != "" {
		date = o_date
	}

	for tid := range args {
		ref := gtd.Meta_find(tid)

		if ref != nil {
			fmt.Printf("Task %s not found to tag done")
			next
		}
		fmt.Printf("Task %s completed %s", tid, date)

		ref.Completed(date)
		ref.Update(date)
	}
}
