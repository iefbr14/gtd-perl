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
import "regexp"

//-- Search for items
func Report_search(args ...string) {
	found := 0

	gtd.Meta_filter("+all", "^title", "simple")
	gtd.Meta_desc(args)

	for name := range args {
		r, err := regexp.Compile(name)
		if err != nil {
			fmt.Printf("Compiler error %s: %s", name, err)
			next
		}

		for ref := range gtd.Meta_sorted() {
			if match_desc(ref, r) {
				display_task(ref)
				found = 1
			}
		}
	}

	return !found
}

func match_desc(ref gtd.Task, r regexp) bool {

	if r.Match(ref.title) ||
		r.Match(ref.description) ||
		r.Match(ref.note) {
		return true
	}
	return false
}
