package Hier::Report::projects;

use strict;
use warnings;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&Report_projects);
}

use Hier::util;
use Hier::Meta;
use Hier::Sort;
use Hier::Option;
use Hier::Format;

my %Meta_key;

sub Report_projects {	#-- List projects -- live, plan or someday
	#meta_filter('+next', '^focus', 'rgpa');
	meta_filter('+p:next', '^focus', 'simple');

	report_projects(1, 'Projects', meta_desc(@_));
}

sub report_projects {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($work_load) = 0;
	my($proj_cnt) = 0;
	my($ref, $proj, %wanted, %counted, %actions);

	# find all next and remember there projects
	for my $ref (meta_matching_type('p')) {
##FILTER	next if $ref->filtered();

		my $pid = $ref->get_tid();
		$wanted{$pid} = $ref;
		$counted{$pid} = 0;
		$actions{$pid} = 0;

		for my $child ($ref->get_children()) {
			$counted{$pid}++ unless $child->filtered();
			$actions{$pid}++;

			$work_load++ unless $child->filtered();
		}
	}

### format:
### ==========================
### Value Vision Role
### -------------------------
### 99	Goal 999 Project
	my($cols) = columns() - 2;

	my($g_id) = 0;
	my($prev_goal) = 0;

	my($r_id) = 0;
	my($prev_role) = 0;

	my($pid, $title, $g_ref, $r_ref);

	for my $ref (sort by_goal_task values %wanted) {

		my($work, $counts) = count_children($ref);
		$work_load += $work;
		display_rgpa($ref, $counts);
#		display_task($ref, $counts);

		++$proj_cnt;

	}
	print "***** Work Load: $proj_cnt Projects, $work_load action items\n";
}

1;  # don't forget to return a true value from the file
