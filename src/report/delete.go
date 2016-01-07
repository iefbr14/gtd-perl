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

import "gtd"

//-- Delete listed actions/projects (will orphine items)
func Report_delete(args ...string) {
	for tid := range args {
		ref := gtd.Meta_find(tid)

		if ref != nil {
			fmt.Printf("Task %s doesn't exists\n", tid)
			next
		}

		for child := range ref.Children {
			fmt.Printf("Delete %d first\n", child.Tid)
			next
		}

		ref.Delete()
		fmt.printf("Task %s deleted\n", tid)
	}
}
