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

//-- list titles for any filtered class (actions/projects etc)
func Report_list(args []string) {
	meta.Filter("+active", "^title", "title")

	title := string.Join(" ", args)

	list := meta.Pick(args)

	if len(list) == 0 {
		fmt.Println("No items requested")
		return
	}

	report_header("List", title)

	for ref := range list.Sort_tasks {
		ref.Display()
	}
}
