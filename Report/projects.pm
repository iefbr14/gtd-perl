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
use Hier::Tasks;

sub Report_projects {	#-- List all projects with actions
	add_filters('+live');
	my $desc = meta_desc(@ARGV);

	if (lc($desc) eq 'plan') {
		add_filters('=plan');
	} elsif (lc($desc) eq 'someday') {
		add_filters('=later');
	} else {
		$desc = "= $desc =";
	}
		
	report_projects(1, 'Projects', meta_desc(@ARGV));
}

sub report_projects {
	my($all, $head, $desc) = @_;

	report_header($head, $desc);

	my($work_load) = 0;
	my($proj_cnt) = 0;
	my($ref, $proj, %wanted, %counted, %actions);

	# find all next and remember there projects
	for my $ref (Hier::Tasks::matching_type('p')) {
		next if $ref->filtered();

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
	my($prev_role) = 0;
	my($pid, $g_ref);
	for my $ref (sort by_goal_task values %wanted) {
		$pid = $ref->get_tid();

		$g_ref = $ref->get_parent();
		$g_id  = $g_ref->get_tid();

		if ($g_id != $prev_goal) {
			print '#', "=" x $cols, "\n" if $prev_goal != 0;
			print "$g_id:\tG:", $g_ref->get_title();

			my $r_ref = $g_ref->get_parent();
			my $r_id = $r_ref->get_tid();
			print " [** R:$r_id: ", $r_ref->get_title(), " **]\n";
			$prev_goal = $g_id;
		} else {
#			print '#', "-" x $cols, "\n";
		}

		$counted{$pid} = 0 unless defined $counted{$pid};
		print "$pid:\tP:", $ref->get_title(), 
			' (', $counted{$pid}, '/', $actions{$pid}, ')',
			"\n";
		++$proj_cnt;

	}
	print "***** Work Load: $proj_cnt Projects, $work_load action items\n";
}

sub by_goal_task {
	return $a->get_parent->get_title() cmp $b->get_parent->get_title()
	    or $a->get_title() cmp $b->get_title()
	    or $a->get_id() <=> $b->get_id();
}

1;  # don't forget to return a true value from the file
