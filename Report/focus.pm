package Hier::Report::focus;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_focus);
}

use Hier::Meta;
use Hier::Sort;
use Hier::Format;
use Hier::Option;

my %Meta_key;

my($Format) = \&focus_summary;

my($Work_load) = 0;
my($Proj_cnt) = 0;

my($Dep) = '';   # Project depends on string

my($Debug) = 0;

sub Report_focus {	#-- List focus -- live, plan or someday
	my($cnt) = 0;

	$Debug = option('Debug', 0);

	meta_filter('+next', '^focus', 'simple');
	my(@list) = meta_pick(@_);
	if (@list == 0) {
		@list = meta_pick('Role');
	}

	report_header(join(' ', "Focus", @_));

	# find all next and remember there focus
	for my $r_ref (sort_tasks @list) {
		unless (check_task($r_ref)) {
			display_rgpa($r_ref, "(PLAN)");
		}
	}
	print "***** Work Load: $Proj_cnt Projects, $Work_load action items\n";
}

###BUG -- borks if dep on completed item
### Re-thing whole logic
sub check_task {
	my($p_ref) = @_;
	my($deps);

	my($id) = $p_ref->get_tid(); 
	printf "X %d %s\n", $id, $p_ref->get_title() if $Debug;

	if ($deps = $p_ref->get_depends()) {	# can't be focus
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
			display_rgpa($Dep, '(DEP)');
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
##FILTER#	next if $ref->filtered();

		my($work, $counts);
		if ($ref->get_type() eq 'p') {
			($work, $counts) = count_children($p_ref);
			$Work_load += $work;
			++$Proj_cnt;
		}

		return 1 if check_task($ref);
	}
	return 0;
}

1;  # don't forget to return a true value from the file
