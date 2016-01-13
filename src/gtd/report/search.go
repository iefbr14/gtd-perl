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
import "regexp"

import "gtd/meta"
import "gtd/display"
import "gtd/task"

//-- Search for items
func Report_search(args []string) int {
	found := 0

	meta.Filter("+all", "^title", "simple")
	meta.Desc(args)

	for _,name := range args {
		re, err := regexp.Compile(name)
		if err != nil {
			fmt.Printf("RE Compile error %s: %s", name, err)
			continue
		}

		for _,ref := range meta.Sorted() {
			if match_desc(ref, re) {
				display.Task(ref, "")
				found = 1
			}
		}
	}

	return found 
}

func match_desc(ref *task.Task, re *regexp.Regexp) bool {
	if re.MatchString(ref.Title) ||
		re.MatchString(ref.Description) ||
		re.MatchString(ref.Note) {
		return true
	}
	return false
}
