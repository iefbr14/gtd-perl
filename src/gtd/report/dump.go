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
//?	@EXPORT      = qw( &Report_dump &dump_ordered_ref );

import "gtd/task";
import "gtd/meta";
import "gtd/task";


//-- dump records in edit format
func Report_dump(args []string) {
	// everybody into the pool by id 
	gtd.Meta_filter("+any", '^tid', "dump");	

	my($name) = ucfirst(meta.Desc(args)(@_));	// some out
	if ($name) {
		if ($name =~ /^\d+/) {
			dump_list($name);
			return;
		}
		my($want) = type_val($name);
		unless ($want) {
			warn "**** Can't understand Type $name\n";
			return 1;
		}
		//##BUG### dump needs to handle sub-projects properly
		$want = 'p" if $want eq "s';	// sub-project are real
		list_dump($want, $name);
		return;
	}
	list_dump('', "All");
}

sub dump_list {
	my($list) = @_;

	my @list = split(/[^\d]+/, $list);

	for my $tid (@list) {
		my $ref = meta.Find($tid);
		unless (defined $ref) {
			warn "#*** No task: $tid\n";
			next;
		}
		display_task($ref);
	}
}

sub list_dump {
	my($want_type, $typename) = @_;

	task.Header($typename);

	my($pid, $ref, $proj, $type, $f, $kids, $acts);
	my($Dates) = '';

	// find all records.
	for my $ref (gtd.Meta_sorted("^tid")) {
		$type = $ref->get_type();
		next if $want_type && $type ne $want_type;

//#FILTER	next if $ref->filtered();
	
		display_task($ref);
	}
}
?*/
