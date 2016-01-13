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
func Report_addplansp(args []string) {
	meta.Filter("+live", "^focus", "plan")
	list := meta.Pick(args)

	limit := 0;
	if len(list) == 0 {
		list = meta.Pick([]string{"Project"});
		limit = option.Int("Limit", 10);
	} else {
		limit = option.Int("Limit", len(list));
	}
	display.Header("Projects needing planning");

	var seen map[int]bool;

	// find all next and remember there focus
	for len(list) > 0 {
		ref := list[0]
		list = list[1:]

		tid := ref.Tid
		
		if seen[tid] {
			continue
		}
		seen[tid] = true

		reason := check_task(ref)
		if reason == "" {
			continue
		}

		list = append(list, ref.Children...);

		reason = task.Join("(",color.On("RED"), reason, color.Off(), ")");
		display.Rgpa(ref, reason);

		limit--;
		if limit <= 0 {
			break
		}
	}
}

func check_task(ref *task.Task) string {
	return ""
}/*?
	my($ref) = @_;

	my($type) = $ref->get_type();

	return unless $ref->is_hier();

	my($pid) = $ref->get_tid();
	my($title) = $ref->get_title();
	my($desc) = $ref->get_description();
	my($result) = $ref->get_note();

	my(@children) = $ref->get_children();

	return "Needs wiki ref" unless $title =~ /\[\[.*\]\]/;

	return if $ref->get_completed();

	return "Needs description" unless $desc;
	return "Needs result" unless $result;

	return "Needs children"  unless @children;

	my($work) = scalar(@children);

	if ($type ne 'a') {
		return "Needs actions" unless $work;
	}

//	if (iscomplex(@children)) {
//		return "Needs progress";
//	}

	return;
}

sub iscomplex {
	return 1 if scalar(@_) >= 8;	// has 8 or more children

	for my $ref (@_) {
		// has a non action ie: complex child
		return 1 if $ref->get_type() ne 'a';	
	}
	return 0;
}
?*/
