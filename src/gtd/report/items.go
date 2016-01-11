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

/*?

import "gtd/task";
import "gtd/meta";
import "gtd/task";
import "gtd/option";
import "gtd/task";

//-- list titles for any filtered class (actions/projects etc)
func Report_items(args []string) {
	// everybody into the pool by name
	meta.Filter("+any", "^title", "item");	

	name := meta.Desc(args);
	if name != "" {
		my($want) = type_val($name);
		if ($want) {
			$want = 'p" if $want eq "s';
			list_items($want, $name);
			return;
		}
		print "**** Can't understand Type $name\n";
		return 1;
	}
	print "No items requested\n";
}

sub list_items {	//-- List projects with waiting-fors
	my($type, $typename) = @_;

	task.Header($typename);

        my($tid, $title, $desc, @list);
        for my $ref (gtd.Meta_matching_type($type)) {
//#FILTER	next if $ref->filtered();

                push(@list, $ref);
        }
        for my $ref (sort_tasks @list) {
		display_task($ref);
        }
}
?*/
