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


use Hier::Meta;
use Hier::Sort;
use Hier::Format;
use Hier::Option;

my %Meta_key;

my($Format) = \&focus_summary;

my($Work_load) = 0;
my($Proj_cnt) = 0;

my($Dep) = '';   # Project depends on string

//-- List focus -- live, plan or someday
func Report_focus(args []string) {
	my($cnt) = 0;

	meta.Filter("+next", '^focus', "simple");
	my(@list) = gtd.Meta_pick(@_);
	if (@list == 0) {
		@list = gtd.Meta_pick("Role");
	}

	if (scalar(@_) > 0) {
		if ($_[0] =~ m/^\d+$/) {
			my($ref) = $list[0];

			my($title) = $ref->get_tid().": ".$ref->get_title();

			report_header(join(' ', "Focus", $title));
		} else {
			report_header(join(' ', "Focus", @_));
		}
	} else {
		report_header("Focus Role");
	}


	// find all next and remember there focus
	for my $ref (sort_tasks @list) {

		unless (check_task($ref)) {
			display_rgpa($ref, "(PLAN)");
		}
	}
	print "***** Work Load: $Proj_cnt Projects, $Work_load action items\n";
}

//##BUG -- borks if dep on completed item
//## Re-thing whole logic
sub check_task {
	my($p_ref) = @_;
	my($deps);

	my($id) = $p_ref->get_tid(); 
	printf "X %d %s\n", $id, $p_ref->get_title() if $Debug;

	if ($deps = $p_ref->get_depends()) {	// can't be focus
		$deps =~ s/\s+/,/g;
		for my $dep (split(',', $deps)) {
			printf "Deps %d on %s\n", $id, $deps if $Debug;

			my($d_ref) = Hier::Tasks::find($dep);
			unless ($d_ref) {
				print "Info: task $id depends on missing task $dep\n";
				next;
			}

			$Dep = $p_ref;
			if (check_task($d_ref)) {
				$Dep = undef;
				return 1;
			}
			$Dep = undef;
		}
		printf "No actions for %d on %s\n", $id, $deps if $Debug;
		return;
	}

	if ($p_ref->get_type() eq 'a') {
		if ($Dep) {
			display_rgpa($Dep, "(DEP)");
			print ("--- ( Depends On ) ----\n");
			display_rgpa($p_ref, '', 1);
		} else {
			display_rgpa($p_ref);
		}
		return 1;
	}

	foreach my $ref (sort_tasks $p_ref->get_children()) {
		next unless $ref->is_nextaction();
		next if $ref->get_completed();
//#FILTER#	next if $ref->filtered();

		my($work, $counts);
		if ($ref->get_type() eq 'p') {
			($work, $counts) = summary_children($p_ref);
			$Work_load += $work;
			++$Proj_cnt;
		}

		return 1 if check_task($ref);
	}
	return 0;
}
