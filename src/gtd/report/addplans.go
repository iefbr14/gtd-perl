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

import "regexp"

import "gtd/color"
import "gtd/display"
import "gtd/meta"
import "gtd/option"
import "gtd/task"

/*
our report_debug = 0;

my($Work_load) = 0;
my($Proj_cnt) = 0;

*/

//-- add plan action items to unplaned projects
func Report_addplans(args []string) int {
	meta.Filter("+live", "^focus", "plan")
	list := meta.Pick(args)

	limit := 0
	if len(list) == 0 {
		list = meta.Pick([]string{"Project"})
		limit = option.Int("Limit", 10)
	} else {
		limit = option.Int("Limit", len(list))
	}
	display.Header("Projects needing planning")

	seen := map[int]bool{}

	// find all next and remember there focus
	for len(list) > 0 {
		ref := list[0]
		list = list[1:]

		tid := ref.Tid

		if seen[tid] {
			continue
		}
		seen[tid] = true

		reason := focus_check_task(ref)
		if reason == "" {
			continue
		}

		list = append(list, ref.Children...)

		reason = task.Join("(", color.On("RED"), reason, color.Off(), ")")
		display.Rgpa(ref, reason)

		limit--
		if limit <= 0 {
			break
		}
	}
	return 0
}

var wikiref_re = regexp.MustCompile(`\[\[.*\]\]`)

func focus_check_task(t *task.Task) string {
	if !t.Is_hier() {
		return ""
	}

	children := t.Children

	if !wikiref_re.MatchString(t.Title) {
		return "Needs wiki ref"
	}

	if t.Completed != "" {
		return ""
	}

	if t.Description == "" {
		return "Needs description"
	}
	if t.Note == "" {
		return "Needs result"
	}

	if len(children) == 0 {
		return "Needs children"
	}

	if t.Type != 'a' {
		if len(children) == 0 {
			return "Needs actions"
		}
	}

	if iscomplex(t.Children) {
		return "Needs progress"
	}

	return ""
}

func iscomplex(list task.Tasks) bool {
	// has 8 or more children
	if len(list) >= 8 {
		return true
	}

	// has a non action ie: complex child
	for _, t := range list {
		if t.Type != 'a' {
			return true
		}
	}
	return false
}
